/**
 * Copyright (c) 2014-present, The osquery authors
 *
 * This source code is licensed as defined by the LICENSE file found in the
 * root directory of this source tree.
 *
 * SPDX-License-Identifier: (Apache-2.0 OR GPL-2.0-only)
 */

#include "buffered.h"

#include <algorithm>
#include <chrono>
#include <thread>

#include <osquery/core/flags.h>
#include <osquery/core/system.h>
#include <osquery/database/database.h>
#include <osquery/logger/logger.h>
#include <osquery/registry/registry.h>
#include <osquery/utils/info/version.h>
#include <osquery/utils/json/json.h>
#include <osquery/utils/system/time.h>
#include <plugins/config/parsers/decorators.h>

namespace osquery {

FLAG(uint64,
     buffered_log_max,
     1000000,
     "Maximum number of logs in buffered output plugins (0 = unlimited)");

const std::chrono::seconds BufferedLogForwarder::kLogPeriod{
    std::chrono::seconds(4)};
const size_t BufferedLogForwarder::kMaxLogLines{1024};

Status BufferedLogForwarder::setUp() {
  // initialize buffer_count_ by scanning the DB
  std::vector<std::string> indexes;
  auto status = scanDatabaseKeys(kLogs, indexes, index_name_, 0);

  if (!status.ok()) {
    return Status(1, "Error scanning for buffered log count");
  }

  RecursiveLock lock(count_mutex_);
  buffer_count_ = indexes.size();
  return Status(0);
}

void BufferedLogForwarder::check() {
  // Get a list of all the buffered log items, with a max of 1024 lines.
  std::vector<std::string> indexes;
  auto status = scanDatabaseKeys(kLogs, indexes, index_name_, max_log_lines_);

  // For each index, accumulate the log line into the result or status set.
  std::vector<std::string> results, statuses;
  iterate(indexes, ([&results, &statuses, this](std::string& index) {
            std::string value;
            auto& target = isResultIndex(index) ? results : statuses;
            if (getDatabaseValue(kLogs, index, value)) {
              target.emplace_back(std::move(value));
            }
          }));

  // If any results/statuses were found in the flushed buffer, send.
  if (results.size() > 0) {
    status = send(results, "result");
    if (!status.ok()) {
      VLOG(1) << "Error sending results to logger: " << status.getMessage();
    } else {
      // Clear the results logs once they were sent.
      iterate(indexes, ([this](std::string& index) {
                if (!isResultIndex(index)) {
                  return;
                }
                deleteValueWithCount(kLogs, index);
              }));
    }
  }

  if (statuses.size() > 0) {
    status = send(statuses, "status");
    if (!status.ok()) {
      VLOG(1) << "Error sending status to logger: " << status.getMessage();
    } else {
      // Clear the status logs once they were sent.
      iterate(indexes, ([this](std::string& index) {
                if (!isStatusIndex(index)) {
                  return;
                }
                deleteValueWithCount(kLogs, index);
              }));
    }
  }

  // Purge any logs exceeding the max after our send attempt
  if (FLAGS_buffered_log_max > 0) {
    purge();
  }
}

void BufferedLogForwarder::purge() {
  RecursiveLock lock(count_mutex_);
  if (buffer_count_ <= FLAGS_buffered_log_max) {
    return;
  }

  size_t purge_count = buffer_count_ - FLAGS_buffered_log_max;

  // Collect purge_count indexes of each type (result/status) before
  // partitioning to find the oldest. Note this assumes that the indexes are
  // returned in ascending lexicographic order (true for RocksDB).
  std::vector<std::string> indexes;
  auto status =
      scanDatabaseKeys(kLogs, indexes, genIndexPrefix(true), purge_count);
  if (!status.ok()) {
    LOG(ERROR) << "Error scanning DB during buffered log purge";
    return;
  }

  LOG(WARNING) << "Purging buffered logs limit (" << FLAGS_buffered_log_max
               << ") exceeded: " << buffer_count_;

  std::vector<std::string> status_indexes;
  status = scanDatabaseKeys(
      kLogs, status_indexes, genIndexPrefix(false), purge_count);
  if (!status.ok()) {
    LOG(ERROR) << "Error scanning DB during buffered log purge";
    return;
  }

  indexes.insert(indexes.end(), status_indexes.begin(), status_indexes.end());

  if (indexes.size() < purge_count) {
    LOG(ERROR) << "Trying to purge " << purge_count << " logs but only found "
               << indexes.size();
    return;
  }

  size_t prefix_size = genIndexPrefix(true).size();
  // Partition the indexes so that the first purge_count elements are the
  // oldest indexes (the ones to be purged)
  std::nth_element(indexes.begin(),
                   indexes.begin() + purge_count - 1,
                   indexes.end(),
                   [&](const std::string& a, const std::string& b) {
                     // Skip the prefix when doing comparisons
                     return a.compare(prefix_size,
                                      std::string::npos,
                                      b,
                                      prefix_size,
                                      std::string::npos) < 0;
                   });
  indexes.erase(indexes.begin() + purge_count, indexes.end());

  // Now only indexes of logs to be deleted remain
  iterate(indexes, [this](const std::string& index) {
    if (!deleteValueWithCount(kLogs, index).ok()) {
      LOG(ERROR) << "Error deleting value during buffered log purge";
    }
  });
}

void BufferedLogForwarder::start() {
  while (!interrupted()) {
    check();

    // Cool off and time wait the configured period.
    pause(std::chrono::milliseconds(log_period_));
  }
}

Status BufferedLogForwarder::logString(const std::string& s, size_t time) {
  std::string index = genResultIndex(time);
  return addValueWithCount(kLogs, index, s);
}

Status BufferedLogForwarder::logStatus(const std::vector<StatusLogLine>& log,
                                       size_t time) {
  // Append decorations to status
  // Assemble a decorations tree to append to each status buffer line.
  auto djson = JSON::newObject();
  std::map<std::string, std::string> decorations;
  getDecorations(decorations);
  for (const auto& decoration : decorations) {
    djson.addCopy(decoration.first, decoration.second);
  }

  for (const auto& item : log) {
    // Convert the StatusLogLine into ptree format, to convert to JSON.
    auto buffer = JSON::newObject();
    buffer.addRef("hostIdentifier", item.identifier);
    buffer.addRef("calendarTime", item.calendar_time);
    buffer.add("unixTime", item.time);
    buffer.add("severity", (google::LogSeverity)item.severity);
    buffer.addRef("filename", item.filename);
    buffer.add("line", item.line);
    buffer.addRef("message", item.message);
    buffer.addRef("version", kVersion);
    if (!decorations.empty()) {
      buffer.add("decorations", djson.doc());
    }

    // Convert to JSON, for storing a string-representation in the database.
    std::string json;
    auto status = buffer.toString(json);
    if (!status.ok()) {
      return status;
    }

    std::string index = genStatusIndex(time);
    status = addValueWithCount(kLogs, index, json);
    if (!status.ok()) {
      // Do not continue if any line fails.
      return status;
    }
  }

  return Status(0);
}

bool BufferedLogForwarder::isIndex(const std::string& index, bool results) {
  size_t target = index_name_.size() + 1;
  return target < index.size() && index.at(target) == (results ? 'r' : 's');
}

bool BufferedLogForwarder::isResultIndex(const std::string& index) {
  return isIndex(index, true);
}

bool BufferedLogForwarder::isStatusIndex(const std::string& index) {
  return isIndex(index, false);
}

std::string BufferedLogForwarder::genResultIndex(size_t time) {
  return genIndex(true, time);
}

std::string BufferedLogForwarder::genStatusIndex(size_t time) {
  return genIndex(false, time);
}

std::string BufferedLogForwarder::genIndexPrefix(bool results) {
  return index_name_ + '_' + ((results) ? 'r' : 's') + '_';
}

std::string BufferedLogForwarder::genIndex(bool results, size_t time) {
  if (time == 0) {
    time = getUnixTime();
  }
  return genIndexPrefix(results) + std::to_string(time) + '_' +
         std::to_string(++log_index_);
}

Status BufferedLogForwarder::addValueWithCount(const std::string& domain,
                                               const std::string& key,
                                               const std::string& value) {
  Status status = setDatabaseValue(domain, key, value);
  if (status.ok()) {
    RecursiveLock lock(count_mutex_);
    buffer_count_++;
  }
  return status;
}

Status BufferedLogForwarder::deleteValueWithCount(const std::string& domain,
                                                  const std::string& key) {
  Status status = deleteDatabaseValue(domain, key);
  if (status.ok()) {
    RecursiveLock lock(count_mutex_);
    if (buffer_count_ > 0) {
      buffer_count_--;
    }
  }
  return status;
}
}
