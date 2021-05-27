/**
 * Copyright (c) 2014-present, The osquery authors
 *
 * This source code is licensed as defined by the LICENSE file found in the
 * root directory of this source tree.
 *
 * SPDX-License-Identifier: (Apache-2.0 OR GPL-2.0-only)
 */

#include <osquery/core/core.h>
#include <osquery/core/tables.h>
#include <osquery/filesystem/fileops.h>
#include <osquery/filesystem/filesystem.h>
#include <osquery/logger/logger.h>
#include <osquery/sql/dynamic_table_row.h>
#include <osquery/utils/conversions/join.h>
#include <osquery/utils/conversions/windows/windows_time.h>
#include <osquery/utils/windows/lzxpress.h>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

namespace osquery {
namespace tables {

const std::string kPrefetchLocation = (getSystemRoot() / "Prefetch\\").string();

struct PrefetchHeader {
  std::uint32_t file_size;
  std::string filename;
  std::string prefetch_hash;
};

// Convert End of string UCHAR vectors to string
std::string ucharToString(std::string_view data) {
  if (data.empty()) {
    return {};
  }

  size_t size = 0;
  size_t string_size = 0;
  int offset = 0;
  std::string string_data;
  // Loop through UTF16 string_view until null-terminated char
  while (true) {
    size = strnlen(&data.data()[offset], data.size());
    if (size > 0) {
      string_size += size;
      string_data += data.data()[offset];
      offset += 2;
      continue;
    }
    break;
  }
  return string_data;
}

std::vector<std::string> parseAccessedData(std::string_view data_view,
                                           bool directory) {
  std::vector<std::string> accessed_data;

  size_t offset = 0;
  while (true) {
    std::string file_accessed = ucharToString(data_view);
    if (file_accessed.size() == 0) {
      break;
    }
    offset = file_accessed.size();
    if (directory) {
      std::string check_name;
      file_accessed = file_accessed.substr(1);
      check_name = file_accessed.substr(0, 4);

      // Check if directory does not begin with \VOL or \DEV, diretory entries
      // often contain remenant data
      if (check_name != "\\VOL" && check_name != "\\DEV") {
        break;
      }
      accessed_data.push_back(file_accessed);
      if (offset > 0) {
        data_view = data_view.substr((offset * 2) + 2);
        continue;
      }
      break;
    }
    accessed_data.push_back(file_accessed);

    if (offset > 0) {
      data_view = data_view.substr((offset * 2) + 2);
      continue;
    }
    break;
  }
  return accessed_data;
}

PrefetchHeader parseHeader(std::string_view data_view) {
  PrefetchHeader header_data;
  memcpy(&header_data.file_size, &data_view[12], sizeof(header_data.file_size));

  data_view.remove_prefix(16);
  header_data.filename = ucharToString(data_view);

  int hash = 0;
  memcpy(&hash, &data_view[60], sizeof(hash));
  header_data.prefetch_hash = (boost::format("%x") % hash).str();
  return header_data;
}

void parsePrefetchData(RowYield& yield,
                       const std::vector<UCHAR>& data,
                       const std::string& file_path,
                       const int& version) {
  if (data.size() < 204) {
    LOG(WARNING) << "Prefetch data format incorrect, expected minimum of 204 "
                    "bytes, got: "
                 << data.size();
    return;
  }

  std::string_view data_view(reinterpret_cast<const char*>(data.data()),
                             data.size());
  auto header = parseHeader(data_view);

  uint32_t offset = 0;
  memcpy(&offset, &data[100], sizeof(offset));
  uint32_t size = 0;
  memcpy(&size, &data[104], sizeof(size));

  if (offset < 0 || offset > data_view.size()) {
    // Unexpected offset.
    return;
  }

  if (size < 0 || offset + size > data_view.size()) {
    // Unexpected size.
    return;
  }

  std::string files_accessed;
  size_t files_accessed_count{0};
  {
    auto files_accessed_view = data_view.substr(offset, size);
    auto files_accessed_list = parseAccessedData(files_accessed_view, false);
    files_accessed = osquery::join(files_accessed_list, ",");
    files_accessed_count = files_accessed_list.size();
  }

  memcpy(&offset, &data[108], sizeof(offset));
  int volume_numbers = 0;
  memcpy(&volume_numbers, &data[112], sizeof(volume_numbers));
  memcpy(&size, &data[116], sizeof(size));

  if (offset < 0 || offset > data_view.size()) {
    // Unexpected offset.
    return;
  }

  if (size < 0 || offset + size > data_view.size()) {
    // Unexpected size.
    return;
  }

  auto dir_accessed_view = data_view.substr(offset, size);
  auto dir_view = dir_accessed_view;

  std::string volume_creation;
  std::string volume_serial;
  std::vector<int> dir_lists;
  {
    std::vector<std::string> volume_creation_list;
    std::vector<std::string> volume_serial_list;
    while (volume_numbers > 0) {
      if (dir_view.size() < 32) {
        // Not enough data to parse.
        break;
      }

      std::int64_t creation = 0;
      memcpy(&creation, &dir_view[8], sizeof(creation));
      LARGE_INTEGER large_time;
      large_time.QuadPart = creation;
      FILETIME file_time;
      file_time.dwHighDateTime = large_time.HighPart;
      file_time.dwLowDateTime = large_time.LowPart;
      LONGLONG creation_time = filetimeToUnixtime(file_time);
      volume_creation_list.push_back(std::to_string(creation_time));
      int serial = 0;
      memcpy(&serial, &dir_view[16], sizeof(serial));
      volume_serial_list.push_back((boost::format("%x") % serial).str());
      volume_numbers -= 1;
      int list_offset = 0;
      memcpy(&list_offset, &dir_view[28], sizeof(list_offset));
      dir_lists.push_back(list_offset);
      // Volume metadata size depends on Prefetch version
      if (version == 30) {
        dir_view.remove_prefix(96);
      } else {
        dir_view.remove_prefix(104);
      }
    }
    volume_creation = osquery::join(volume_creation_list, ",");
    volume_serial = osquery::join(volume_serial_list, ",");
  }

  std::string dirs_accessed;
  size_t dirs_accessed_count{0};
  {
    std::vector<std::string> dirs_accessed_list;
    for (const auto& dir_list : dir_lists) {
      auto dir_view = dir_accessed_view.substr(dir_list);
      auto dir = parseAccessedData(dir_view, true);
      dirs_accessed_list.insert(
          dirs_accessed_list.end(), dir.begin(), dir.end());
    }
    dirs_accessed = osquery::join(dirs_accessed_list, ",");
    dirs_accessed_count = dirs_accessed_list.size();
  }

  std::string timestamp_list;
  std::string last_execution_time;
  {
    std::vector<std::int64_t> run_times;
    std::int64_t times_run = 0;
    // Win8+ Prefetch can contain up to eight timestamps
    // If the eight timestamps are not filled, they are set to 0
    if (version == 23) {
      memcpy(&times_run, &data[128], sizeof(times_run));
      run_times.push_back(times_run);
    } else {
      int time_i = 0;
      int time_offset = 128;
      while (time_i < 8) {
        memcpy(&times_run, &data[time_offset], sizeof(times_run));
        run_times.push_back(times_run);
        time_i++;
        time_offset += 8;
      }
    }

    std::vector<std::string> timestamps;
    for (const auto& run_time : run_times) {
      if (run_time == 0ll) {
        break;
      }
      LARGE_INTEGER large_time;
      large_time.QuadPart = run_time;
      FILETIME file_time;
      file_time.dwHighDateTime = large_time.HighPart;
      file_time.dwLowDateTime = large_time.LowPart;
      LONGLONG runtime = filetimeToUnixtime(file_time);
      timestamps.push_back(std::to_string(runtime));
    }
    timestamp_list = osquery::join(timestamps, ",");
    last_execution_time = timestamps[0];
  }

  int run_count = 0;
  if (version == 23) {
    memcpy(&run_count, &data[152], sizeof(run_count));
  } else if (version == 26) {
    memcpy(&run_count, &data[208], sizeof(run_count));
  } else {
    memcpy(&run_count, &data[200], sizeof(run_count));
  }
  auto r = make_table_row();
  r["path"] = file_path;
  r["filename"] = SQL_TEXT(header.filename);
  r["hash"] = header.prefetch_hash;
  r["size"] = INTEGER(header.file_size);
  r["accessed_files_count"] = INTEGER(files_accessed_count);
  r["accessed_files"] = std::move(files_accessed);
  r["volume_serial"] = std::move(volume_serial);
  r["volume_creation"] = std::move(volume_creation);
  r["accessed_directories_count"] = INTEGER(dirs_accessed_count);
  r["accessed_directories"] = std::move(dirs_accessed);
  r["last_execution_time"] = last_execution_time;
  r["execution_times"] = std::move(timestamp_list);
  r["count"] = INTEGER(run_count);
  yield(std::move(r));
}

void parsePrefetchVersion(RowYield& yield,
                          const std::vector<UCHAR>& data,
                          const std::string& file_path) {
  int version = 0;
  memcpy(&version, &data[0], sizeof(version));
  // Currently supports Win7 and higher
  if (version == 30 || version == 23 || version == 26) {
    parsePrefetchData(yield, data, file_path, version);
  } else {
    LOG(WARNING) << "Unsupported prefetch file: " << file_path;
  }
}

void parsePrefetch(const std::string& file, RowYield& yield) {
  LOG(INFO) << "Parsing prefetch file: " << file;
  std::ifstream input_file(file, std::ios::in | std::ios::binary);
  std::vector<UCHAR> compressed_data(
      (std::istreambuf_iterator<char>(input_file)),
      (std::istreambuf_iterator<char>()));
  input_file.close();

  if (compressed_data.size() < 8) {
    // Not enough data to determine header_size and size.
    return;
  }

  std::int32_t header_sig = 0;
  memcpy(&header_sig, &compressed_data[0], sizeof(header_sig));
  std::int32_t size = 0;
  memcpy(&size, &compressed_data[4], sizeof(size));
  std::vector<UCHAR> data;
  // Check for compression signature MAM04. Prefetch may be compressed on Win8+
  if (header_sig == 72171853) {
    auto expected_data = decompressLZxpress(compressed_data, size);
    if (expected_data.isError()) {
      return;
    }
    data = expected_data.take();
  } else {
    data = std::move(compressed_data);
  }

  if (data.size() < 8) {
    // Not enough data to determine header.
    return;
  }

  std::int32_t header = 0;
  memcpy(&header, &data[4], sizeof(header));
  // Check for "SCCA" signature
  if (header != 1094927187) {
    LOG(WARNING) << "Unsupported prefetch file, missing header: " << file;
    return;
  }
  parsePrefetchVersion(yield, data, file);
}

void genPrefetch(RowYield& yield, QueryContext& context) {
  // There are no required columns for prefetch, but prefetch can take a bit of
  // time to parse. If a path constraint is provided parse only prefetch file(s)
  // in path
  auto paths = context.constraints["path"].getAll(EQUALS);
  // Expand constraints
  context.expandConstraints(
      "path",
      LIKE,
      paths,
      ([&](const std::string& pattern, std::set<std::string>& out) {
        std::vector<std::string> patterns;
        auto status =
            resolveFilePattern(pattern, patterns, GLOB_ALL | GLOB_NO_CANON);
        if (status.ok()) {
          for (const auto& resolved : patterns) {
            out.insert(resolved);
          }
        }
        return status;
      }));

  auto prefetch_files = std::vector(paths.begin(), paths.end());
  if (prefetch_files.empty()) {
    listFilesInDirectory(kPrefetchLocation, prefetch_files);
  }

  for (const auto& file : prefetch_files) {
    if (!boost::algorithm::iends_with(file, ".pf")) {
      continue;
    }

    boost::system::error_code ec;
    if (boost::filesystem::is_regular_file(file, ec) && !ec) {
      parsePrefetch(file, yield);
    }
  }
}
} // namespace tables
} // namespace osquery