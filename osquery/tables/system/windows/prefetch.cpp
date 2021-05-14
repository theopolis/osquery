/**
 * Copyright (c) 2014-present, The osquery authors
 *
 * This source code is licensed as defined by the LICENSE file found in the
 * root directory of this source tree.
 *
 * SPDX-License-Identifier: (Apache-2.0 OR GPL-2.0-only)
 */

#include "osquery/filesystem/fileops.h"
#include <osquery/core/core.h>
#include <osquery/core/tables.h>
#include <osquery/filesystem/filesystem.h>
#include <osquery/logger/logger.h>
#include <osquery/sql/dynamic_table_row.h>
#include <osquery/tables/system/windows/prefetch.h>
#include <osquery/utils/conversions/join.h>
#include <osquery/utils/conversions/windows/windows_time.h>
#include <osquery/utils/windows/lzxpress.h>

#include <boost/filesystem.hpp>
#include <boost/format.hpp>

namespace osquery {
namespace tables {

const std::string kPrefetchLocation = (getSystemRoot() / "Prefetch\\").string();

// Convert End of string UCHAR vectors to string
std::string ucharToString(const std::vector<UCHAR>& data) {
  int data_char = 0;
  std::string data_string;
  while (data[data_char] != '\0') {
    data_string += data[data_char];
    data_char++;
    if (data[data_char] == '\0') {
      data_char++;
    }
  }
  return data_string;
}

ExpectedPrefetchAccessedData parseAccessedData(const std::vector<UCHAR>& data,
                                               const std::string& type) {
  std::vector<std::string> accessed_data;
  std::vector<UCHAR> pf_data = data;
  while (pf_data.size() > 0) {
    std::string file_accessed = ucharToString(pf_data);
    if (type == "directory") {
      if (file_accessed.size() < 4) {
        break;
      }
      std::string check_name = "";
      file_accessed = file_accessed.substr(1);
      check_name = file_accessed.substr(0, 4);

      // Check if directory does not begin with \VOL or \DEV, diretory entries
      // often contain remenant data
      if (check_name != "\\VOL" && check_name != "\\DEV") {
        break;
      }
      accessed_data.push_back(file_accessed);
      pf_data.erase(pf_data.begin(),
                    pf_data.begin() + (file_accessed.size() * 2) + 4);
      continue;
    }
    accessed_data.push_back(file_accessed);

    pf_data.erase(pf_data.begin(),
                  pf_data.begin() + (file_accessed.size() * 2) + 2);
  }
  return ExpectedPrefetchAccessedData::success(accessed_data);
}

ExpectedPrefetchHeader parseHeader(const std::vector<UCHAR>& data) {
  std::vector<UCHAR> prefetch_data = data;
  PrefetchHeader header_data;
  header_data.file_size = *reinterpret_cast<int*>(&prefetch_data[12]);
  std::vector<UCHAR> filename(prefetch_data.begin() + 16,
                              prefetch_data.begin() + 76);
  header_data.filename = ucharToString(filename);
  int hash = *reinterpret_cast<int*>(&prefetch_data[76]);
  header_data.prefetch_hash = (boost::format("%x") % hash).str();
  return ExpectedPrefetchHeader::success(header_data);
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
  std::vector<UCHAR> prefetch_data = data;
  auto expected_header = parseHeader(prefetch_data);

  PrefetchHeader header = expected_header.take();
  int offset = *reinterpret_cast<int*>(&prefetch_data[100]);
  int size = *reinterpret_cast<int*>(&prefetch_data[104]);
  std::vector<UCHAR> files_accessed(prefetch_data.begin() + offset,
                                    prefetch_data.begin() + offset + size);

  const std::string filename = "filename";
  auto expected_accessed_file_list =
      parseAccessedData(files_accessed, filename);

  std::vector<std::string> accessed_file_list =
      expected_accessed_file_list.take();
  std::string files_accessed_list = osquery::join(accessed_file_list, ",");

  offset = *reinterpret_cast<int*>(&prefetch_data[108]);
  int volume_numbers = *reinterpret_cast<int*>(&prefetch_data[112]);
  size = *reinterpret_cast<int*>(&prefetch_data[116]);
  std::vector<UCHAR> dir_accessed(prefetch_data.begin() + offset,
                                  prefetch_data.begin() + offset + size);
  std::vector<UCHAR> dir = dir_accessed;
  std::vector<std::string> volume_creation_list;
  std::vector<std::string> volume_serial_list;
  std::vector<int> dir_lists;
  while (volume_numbers > 0) {
    long long creation = *reinterpret_cast<long long*>(&dir[8]);
    LARGE_INTEGER large_time;
    large_time.QuadPart = creation;
    FILETIME file_time;
    file_time.dwHighDateTime = large_time.HighPart;
    file_time.dwLowDateTime = large_time.LowPart;
    long long creation_time = filetimeToUnixtime(file_time);
    volume_creation_list.push_back(std::to_string(creation_time));
    int serial = *reinterpret_cast<int*>(&dir[16]);
    volume_serial_list.push_back((boost::format("%x") % serial).str());
    volume_numbers -= 1;
    int list_offset = *reinterpret_cast<int*>(&dir[28]);
    dir_lists.push_back(list_offset);
    // Volume metadata size depends on Prefetch version
    if (version == 30) {
      dir.erase(dir.begin(), dir.begin() + 96);
    } else {
      dir.erase(dir.begin(), dir.begin() + 104);
    }
  }
  const std::string directory = "directory";
  std::vector<std::string> accessed_dirs_list;
  int volume = 0;
  while (dir_lists.size() > 0) {
    std::vector<UCHAR> data_dir(dir_accessed.begin() + dir_lists[volume],
                                dir_accessed.end());
    auto expected_accessed_dirs_list = parseAccessedData(data_dir, directory);

    std::vector<std::string> dir_data = expected_accessed_dirs_list.take();
    accessed_dirs_list.insert(
        accessed_dirs_list.end(), dir_data.begin(), dir_data.end());
    dir_lists.erase(dir_lists.begin());
    volume++;
  }
  std::string dirs_accessed_list = osquery::join(accessed_dirs_list, ",");
  std::vector<long long> run_times;
  // Win8+ Prefetch can contain up to eight timestamps
  // If the eight timestamps are not filled, they are set to 0
  if (version == 23) {
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[128]));
  } else {
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[128]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[136]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[144]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[152]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[160]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[168]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[176]));
    run_times.push_back(*reinterpret_cast<long long*>(&prefetch_data[184]));
  }
  std::vector<std::string> timestamps;
  int times = 0;
  while (run_times.size() != 0) {
    if (run_times[times] == 0ll) {
      break;
    }
    LARGE_INTEGER large_time;
    large_time.QuadPart = run_times[times];
    FILETIME file_time;
    file_time.dwHighDateTime = large_time.HighPart;
    file_time.dwLowDateTime = large_time.LowPart;
    long long runtime = filetimeToUnixtime(file_time);
    std::string time = std::to_string(runtime);
    timestamps.push_back(time);
    run_times.erase(run_times.begin());
    times++;
  }
  std::string timestamp_list = osquery::join(timestamps, ",");
  int run_count = 0;
  if (version == 23) {
    run_count = *reinterpret_cast<int*>(&prefetch_data[152]);
  } else if (version == 26) {
    run_count = *reinterpret_cast<int*>(&prefetch_data[208]);
  } else {
    run_count = *reinterpret_cast<int*>(&prefetch_data[200]);
  }

  auto r = make_table_row();
  r["path"] = file_path;
  r["filename"] = header.filename;
  r["hash"] = header.prefetch_hash;
  r["size"] = INTEGER(header.file_size);
  r["number_of_accessed_files"] = INTEGER(accessed_file_list.size());
  r["accessed_files"] = files_accessed_list;
  r["volume_serial"] = osquery::join(volume_serial_list, ",");
  r["volume_creation"] = osquery::join(volume_creation_list, ",");
  r["number_of_accessed_directories"] = INTEGER(accessed_dirs_list.size());
  r["accessed_directories"] = dirs_accessed_list;
  r["last_execution_time"] = INTEGER(timestamps[0]);
  r["execution_times"] = timestamp_list;
  r["count"] = INTEGER(run_count);
  yield(std::move(r));
}

void parsePrefetchVersion(RowYield& yield,
                          const std::vector<UCHAR>& data,
                          const std::string& file_path) {
  std::vector<UCHAR> prefetch_data = data;
  int version = *reinterpret_cast<int*>(&prefetch_data[0]);
  // Currently supports Win7 and higher
  if (version == 30 || version == 23 || version == 26) {
    parsePrefetchData(yield, prefetch_data, file_path, version);
  } else {
    LOG(WARNING) << "Unsupported prefetch file: " << file_path;
  }
}

void parsePrefetch(const std::vector<std::string>& prefetch_files,
                   RowYield& yield) {
  for (const auto& file : prefetch_files) {
    if (boost::algorithm::iends_with(file, ".pf") &&
        boost::filesystem::is_regular_file(file)) {
      LOG(INFO) << "Parsing prefetch file: " << file;
      std::ifstream input_file(file, std::ios::in | std::ios::binary);
      std::vector<char> compressed_data(
          (std::istreambuf_iterator<char>(input_file)),
          (std::istreambuf_iterator<char>()));
      input_file.close();

      long header_sig = *reinterpret_cast<long*>(&compressed_data[0]);
      long size = *reinterpret_cast<long*>(&compressed_data[4]);
      std::vector<UCHAR> data;
      std::string file_path = file;
      // Check for compression signature MAM04. Prefetch may be compressed on
      // Win8+
      if (header_sig == 72171853) {
        auto expected_data = decompressLZxpress(compressed_data, size);
        if (expected_data.isError()) {
          continue;
        }
        data = expected_data.take();
      } else {
        std::transform(
            compressed_data.begin(),
            compressed_data.end(),
            std::back_inserter(data),
            [](char char_data) { return reinterpret_cast<UCHAR&>(char_data); });
      }
      long header = *reinterpret_cast<long*>(&data[4]);
      // Check for "SCCA" signature
      if (header != 1094927187) {
        LOG(WARNING) << "Unsupported prefetch file, missing header: "
                     << file_path;
        continue;
      }
      parsePrefetchVersion(yield, data, file_path);
    }
  }
}

void genPrefetch(RowYield& yield, QueryContext& context) {
  std::vector<std::string> prefetch_files;

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
  if (paths.size() > 0) {
    std::vector<std::string> input_files(paths.begin(), paths.end());
    parsePrefetch(input_files, yield);
  } else if (listFilesInDirectory(kPrefetchLocation, prefetch_files)) {
    parsePrefetch(prefetch_files, yield);
  } else {
    LOG(WARNING) << "No prefetch files to parse";
  }
}
} // namespace tables
} // namespace osquery