/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <algorithm>
#include <random>

#include <osquery/core.h>
#include <osquery/hash.h>
#include <osquery/logger.h>
#include <osquery/packs.h>
#include <osquery/sql.h>

#include "osquery/core/conversions.h"

namespace osquery {

FLAG(uint64,
     pack_refresh_interval,
     3600,
     "Cache expiration for a packs discovery queries");

FLAG(string, pack_delimiter, "_", "Delimiter for pack and query names");

FLAG(uint64, schedule_splay_percent, 10, "Percent to splay config times");

FLAG(uint64,
     schedule_default_interval,
     3600,
     "Query interval to use if none is provided");

size_t splayValue(size_t original, size_t splayPercent) {
  if (splayPercent == 0 || splayPercent > 100) {
    return original;
  }

  float percent_to_modify_by = (float)splayPercent / 100;
  size_t possible_difference = original * percent_to_modify_by;
  size_t max_value = original + possible_difference;
  size_t min_value = std::max((size_t)1, original - possible_difference);

  if (max_value == min_value) {
    return max_value;
  }

  std::default_random_engine generator;
  generator.seed(
      std::chrono::high_resolution_clock::now().time_since_epoch().count());
  std::uniform_int_distribution<uint32_t> distribution(min_value, max_value);
  return distribution(generator);
}

size_t getMachineShard(const std::string& hostname = "", bool force = false) {
  static size_t shard = 0;
  if (shard > 0 && !force) {
    return shard;
  }

  // An optional input hostname may override hostname detection for testing.
  auto hn = (hostname.empty()) ? getHostname() : hostname;
  auto hn_hash = hashFromBuffer(HASH_TYPE_MD5, hn.c_str(), hn.size());
  if (hn_hash.size() >= 2) {
    long hn_char;
    if (safeStrtol(hn_hash.substr(0, 2), 16, hn_char)) {
      shard = (hn_char * 100) / 255;
    }
  }
  return shard;
}

size_t restoreSplayedValue(const std::string& name, size_t interval) {
  // Attempt to restore a previously-calculated splay.
  std::string content;
  getDatabaseValue(kPersistentSettings, "interval." + name, content);
  if (!content.empty()) {
    // This query name existed before, check the last requested interval.
    auto details = osquery::split(content, ":");
    if (details.size() == 2) {
      long last_interval, last_splay;
      if (safeStrtol(details[0], 10, last_interval) &&
          safeStrtol(details[1], 10, last_splay)) {
        if (last_interval == static_cast<long>(interval) && last_splay > 0) {
          // This is a matching interval, use the previous splay.
          return static_cast<size_t>(last_splay);
        }
      }
    }
  }

  // If the splayed interval was not restored from the database.
  auto splay = splayValue(interval, FLAGS_schedule_splay_percent);
  content = std::to_string(interval) + ":" + std::to_string(splay);
  setDatabaseValue(kPersistentSettings, "interval." + name, content);
  return splay;
}

void Pack::initialize(const std::string& name,
                      const std::string& source,
                      const Json::Value& tree) {
  name_ = name;
  source_ = source;
  // Check the shard limitation, shards falling below this value are included.
  if (tree.isMember("shard")) {
    shard_ = tree["shard"].asUInt();
  }

  // Check for a platform restriction.
  platform_.clear();
  if (tree.isMember("platform") > 0) {
    platform_ = tree["platform"].asString();
  }

  // Check for a version restriction.
  version_.clear();
  if (tree.isMember("version")) {
    version_ = tree["version"].asString();
  }

  // Apply the shard, platform, and version checking.
  // It is important to set each value such that the packs meta-table can report
  // each of the restrictions.
  if ((shard_ > 0 && shard_ < getMachineShard()) || !checkPlatform() ||
      !checkVersion()) {
    return;
  }

  discovery_queries_.clear();
  if (tree.isMember("discovery")) {
    for (const auto& item : tree["discovery"]) {
      discovery_queries_.push_back(item.asString());
    }
  }

  // Initialize a discovery cache at time 0.
  discovery_cache_ = std::make_pair<size_t, bool>(0, false);
  valid_ = true;

  // If the splay percent is less than 1 reset to a sane estimate.
  if (FLAGS_schedule_splay_percent <= 1) {
    FLAGS_schedule_splay_percent = 10;
  }

  schedule_.clear();
  if (!tree.isMember("queries") || !tree["queries"].isObject()) {
    // This pack contained no queries.
    return;
  }

  // Iterate the queries (or schedule) and check platform/version/sanity.
  for (auto q = tree["queries"].begin(); q != tree["queries"].end(); q++) {
    if (q->isMember("shard") > 0) {
      auto shard = q->get("shard", 0).asUInt();
      if (shard > 0 && shard < getMachineShard()) {
        continue;
      }
    }

    if (q->isMember("platform")) {
      if (!checkPlatform(q->get("platform", "").asString())) {
        continue;
      }
    }

    if (q->isMember("version")) {
      if (!checkVersion(q->get("version", "").asString())) {
        continue;
      }
    }

    ScheduledQuery query;
    auto query_name = q.name();
    query.query = q->get("query", "").asString();
    query.interval =
        q->get("interval", (Json::UInt64)FLAGS_schedule_default_interval)
            .asUInt();
    if (query.interval <= 0 || query.query.empty() || query.interval > 592200) {
      // Invalid pack query.
      VLOG(1) << "Query has invalid interval: " << query_name << ": "
              << query.interval;
      continue;
    }

    query.splayed_interval = restoreSplayedValue(query_name, query.interval);
    query.options["snapshot"] = q->get("snapshot", false).asBool();
    query.options["removed"] = q->get("removed", true).asBool();
    schedule_[query_name] = query;
  }
}

const std::map<std::string, ScheduledQuery>& Pack::getSchedule() const {
  return schedule_;
}

const std::vector<std::string>& Pack::getDiscoveryQueries() const {
  return discovery_queries_;
}

const PackStats& Pack::getStats() const { return stats_; }

const std::string& Pack::getPlatform() const { return platform_; }

const std::string& Pack::getVersion() const { return version_; }

bool Pack::shouldPackExecute() { return (valid_ && checkDiscovery()); }

const std::string& Pack::getName() const { return name_; }

const std::string& Pack::getSource() const { return source_; }

void Pack::setName(const std::string& name) { name_ = name; }

bool Pack::checkPlatform() const { return checkPlatform(platform_); }

bool Pack::checkPlatform(const std::string& platform) const {
  if (platform.empty() || platform == "null") {
    return true;
  }

#ifdef __linux__
  if (platform.find("linux") != std::string::npos) {
    return true;
  }
#endif

  if (platform.find("any") != std::string::npos ||
      platform.find("all") != std::string::npos) {
    return true;
  }
  return (platform.find(kSDKPlatform) != std::string::npos);
}

bool Pack::checkVersion() const { return checkVersion(version_); }

bool Pack::checkVersion(const std::string& version) const {
  if (version.empty() || version == "null") {
    return true;
  }

  auto required_version = split(version, ".");
  auto build_version = split(kSDKVersion, ".");

  size_t index = 0;
  for (const auto& chunk : build_version) {
    if (required_version.size() <= index) {
      return true;
    }
    try {
      if (std::stoi(chunk) < std::stoi(required_version[index])) {
        return false;
      } else if (std::stoi(chunk) > std::stoi(required_version[index])) {
        return true;
      }
    } catch (const std::invalid_argument& e) {
      if (chunk.compare(required_version[index]) < 0) {
        return false;
      }
    }
    index++;
  }
  return true;
}

bool Pack::checkDiscovery() {
  stats_.total++;
  size_t current = osquery::getUnixTime();
  if ((current - discovery_cache_.first) < FLAGS_pack_refresh_interval) {
    stats_.hits++;
    return discovery_cache_.second;
  }

  stats_.misses++;
  discovery_cache_.first = current;
  discovery_cache_.second = true;
  for (const auto& q : discovery_queries_) {
    auto sql = SQL(q);
    if (!sql.ok()) {
      LOG(WARNING) << "Discovery query failed (" << q
                   << "): " << sql.getMessageString();
      discovery_cache_.second = false;
      break;
    }
    if (sql.rows().size() == 0) {
      discovery_cache_.second = false;
      break;
    }
  }
  return discovery_cache_.second;
}
}
