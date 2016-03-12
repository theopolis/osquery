/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <set>

#include <json/reader.h>
#include <json/writer.h>

#include <boost/lexical_cast.hpp>

#include <osquery/database.h>
#include <osquery/logger.h>

namespace osquery {

CLI_FLAG(bool, database_dump, false, "Dump the contents of the backing store");

CLI_FLAG(string,
         database_path,
         "/var/osquery/osquery.db",
         "If using a disk-based backing store, specify a path");
FLAG_ALIAS(std::string, db_path, database_path);

CLI_FLAG(bool,
         database_in_memory,
         false,
         "Keep osquery backing-store in memory");
FLAG_ALIAS(bool, use_in_memory_database, database_in_memory);

#if defined(SKIP_ROCKSDB)
#define DATABASE_PLUGIN "sqlite"
#else
#define DATABASE_PLUGIN "rocksdb"
#endif
const std::string kInternalDatabase = DATABASE_PLUGIN;

const std::string kPersistentSettings = "configurations";
const std::string kQueries = "queries";
const std::string kEvents = "events";
const std::string kLogs = "logs";

const std::vector<std::string> kDomains = {kPersistentSettings, kQueries,
                                           kEvents, kLogs};

bool DatabasePlugin::kDBHandleOptionAllowOpen(false);
bool DatabasePlugin::kDBHandleOptionRequireWrite(false);
std::atomic<bool> DatabasePlugin::kCheckingDB(false);

/////////////////////////////////////////////////////////////////////////////
// Row - the representation of a row in a set of database results. Row is a
// simple map where individual column names are keys, which map to the Row's
// respective value
/////////////////////////////////////////////////////////////////////////////

Status serializeRow(const Row& r, Json::Value& tree) {
  try {
    for (auto& i : r) {
      tree[i.first] = i.second;
    }
  } catch (const std::exception& e) {
    return Status(1, e.what());
  }
  return Status(0, "OK");
}

Status serializeRowJSON(const Row& r, std::string& json) {
  Json::Value tree;
  auto status = serializeRow(r, tree);
  if (!status.ok()) {
    return status;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

Status deserializeRow(const Json::Value& tree, Row& r) {
  for (auto it = tree.begin(); it != tree.end(); it++) {
    auto column = it.name();
    if (!column.empty()) {
      r[column] = it->asString();
    }
  }
  return Status(0, "OK");
}

Status deserializeRowJSON(const std::string& json, Row& r) {
  Json::Value tree;
  Json::Reader reader;
  if (!reader.parse(json, tree, false)) {
    return Status(1, "Cannot parse JSON");
  }
  return deserializeRow(tree, r);
}

/////////////////////////////////////////////////////////////////////////////
// QueryData - the representation of a database query result set. It's a
// vector of rows
/////////////////////////////////////////////////////////////////////////////

Status serializeQueryData(const QueryData& q, Json::Value& tree) {
  for (const auto& r : q) {
    Json::Value serialized;
    auto s = serializeRow(r, serialized);
    if (!s.ok()) {
      return s;
    }
    tree.append(serialized);
  }
  return Status(0, "OK");
}

Status serializeQueryDataJSON(const QueryData& q, std::string& json) {
  Json::Value tree;
  auto status = serializeQueryData(q, tree);
  if (!status.ok()) {
    return status;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

Status deserializeQueryData(const Json::Value& tree, QueryData& qd) {
  for (const auto& item : tree) {
    Row r;
    auto status = deserializeRow(item, r);
    if (!status.ok()) {
      return status;
    }
    qd.push_back(r);
  }
  return Status(0, "OK");
}

Status deserializeQueryDataJSON(const std::string& json, QueryData& qd) {
  Json::Value tree;
  Json::Reader reader;

  if (!reader.parse(json, tree, false)) {
    return Status(1, "Could not parse JSON");
  }
  return deserializeQueryData(tree, qd);
}

/////////////////////////////////////////////////////////////////////////////
// DiffResults - the representation of two diffed QueryData result sets.
// Given and old and new QueryData, DiffResults indicates the "added" subset
// of rows and the "removed" subset of Rows
/////////////////////////////////////////////////////////////////////////////

Status serializeDiffResults(const DiffResults& d, Json::Value& tree) {
  {
    Json::Value added;
    auto status = serializeQueryData(d.added, added);
    if (!status.ok()) {
      return status;
    }
    tree["added"] = added;
  }

  {
    Json::Value removed;
    auto status = serializeQueryData(d.removed, removed);
    if (!status.ok()) {
      return status;
    }
    tree["removed"] = removed;
  }
  return Status(0, "OK");
}

Status deserializeDiffResults(const Json::Value& tree, DiffResults& dr) {
  if (tree.isMember("added")) {
    auto status = deserializeQueryData(tree["added"], dr.added);
    if (!status.ok()) {
      return status;
    }
  }

  if (tree.isMember("removed")) {
    auto status = deserializeQueryData(tree["removed"], dr.removed);
    if (!status.ok()) {
      return status;
    }
  }
  return Status(0, "OK");
}

Status serializeDiffResultsJSON(const DiffResults& d, std::string& json) {
  Json::Value tree;
  auto status = serializeDiffResults(d, tree);
  if (!status.ok()) {
    return status;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

DiffResults diff(const QueryData& old, const QueryData& current) {
  DiffResults r;
  QueryData overlap;

  for (const auto& i : current) {
    auto item = std::find(old.begin(), old.end(), i);
    if (item != old.end()) {
      overlap.push_back(i);
    } else {
      r.added.push_back(i);
    }
  }

  std::multiset<Row> overlap_set(overlap.begin(), overlap.end());
  std::multiset<Row> old_set(old.begin(), old.end());
  std::set_difference(old_set.begin(),
                      old_set.end(),
                      overlap_set.begin(),
                      overlap_set.end(),
                      std::back_inserter(r.removed));
  return r;
}

/////////////////////////////////////////////////////////////////////////////
// QueryLogItem - the representation of a log result occuring when a
// scheduled query yields operating system state change.
/////////////////////////////////////////////////////////////////////////////

Status serializeQueryLogItem(const QueryLogItem& i, Json::Value& tree) {
  Json::Value results_tree;
  if (i.results.added.size() > 0 || i.results.removed.size() > 0) {
    auto status = serializeDiffResults(i.results, results_tree);
    if (!status.ok()) {
      return status;
    }
    tree["diffResults"] = results_tree;
  } else {
    auto status = serializeQueryData(i.snapshot_results, results_tree);
    if (!status.ok()) {
      return status;
    }
    tree["snapshot"] = results_tree;
  }

  tree["name"] = i.name;
  tree["hostIdentifier"] = i.identifier;
  tree["calendarTime"] = i.calendar_time;
  tree["unixTime"] = i.time;
  return Status(0, "OK");
}

Status serializeQueryLogItemJSON(const QueryLogItem& i, std::string& json) {
  Json::Value tree;
  auto status = serializeQueryLogItem(i, tree);
  if (!status.ok()) {
    return status;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

Status deserializeQueryLogItem(const Json::Value& tree, QueryLogItem& item) {
  if (tree.isMember("diffResults")) {
    auto status = deserializeDiffResults(tree["diffResults"], item.results);
    if (!status.ok()) {
      return status;
    }
  } else if (tree.isMember("snapshot")) {
    auto status = deserializeQueryData(tree["snapshot"], item.snapshot_results);
    if (!status.ok()) {
      return status;
    }
  }

  item.name = tree["name"].asString();
  item.identifier = tree["hostIdentifier"].asString();
  item.calendar_time = tree["calendarTime"].asString();
  item.time = tree["unixTime"].asUInt();
  return Status(0, "OK");
}

Status deserializeQueryLogItemJSON(const std::string& json,
                                   QueryLogItem& item) {
  Json::Value tree;
  Json::Reader reader;

  if (!reader.parse(json, tree, false)) {
    return Status(1, "Could not parse JSON");
  }
  return deserializeQueryLogItem(tree, item);
}

Status serializeEvent(const QueryLogItem& item,
                      const Json::Value& event,
                      Json::Value& tree) {
  tree["name"] = item.name;
  tree["hostIdentifier"] = item.identifier;
  tree["calendarTime"] = item.calendar_time;
  tree["unixTime"] = item.time;

  Json::Value columns;
  for (auto it = event.begin(); it != event.end(); it++) {
    // Yield results as a "columns." map to avoid namespace collisions.
    columns[it.name()] = it->asString();
  }

  tree["columns"] = columns;
  return Status(0, "OK");
}

Status serializeQueryLogItemAsEvents(const QueryLogItem& i, Json::Value& tree) {
  Json::Value diff_results;
  auto status = serializeDiffResults(i.results, diff_results);
  if (!status.ok()) {
    return status;
  }

  for (auto it = diff_results.begin(); it != diff_results.end(); it++) {
    for (auto& row : *it) {
      Json::Value event;
      serializeEvent(i, row, event);
      event["action"] = it.name();
      tree.append(event);
    }
  }
  return Status(0, "OK");
}

Status serializeQueryLogItemAsEventsJSON(const QueryLogItem& i,
                                         std::vector<std::string>& items) {
  Json::Value tree;
  auto status = serializeQueryLogItemAsEvents(i, tree);
  if (!status.ok()) {
    return status;
  }

  for (auto& event : tree) {
    Json::FastWriter writer;
    items.push_back(writer.write(event.asString()));
  }
  return Status(0, "OK");
}

bool addUniqueRowToQueryData(QueryData& q, const Row& r) {
  if (std::find(q.begin(), q.end(), r) != q.end()) {
    return false;
  }
  q.push_back(r);
  return true;
}

bool DatabasePlugin::initPlugin() {
  // Initialize the database plugin using the flag.
  return Registry::setActive("database", kInternalDatabase).ok();
}

void DatabasePlugin::shutdown() {
  auto datbase_registry = Registry::registry("database");
  for (auto& plugin : datbase_registry->names()) {
    datbase_registry->remove(plugin);
  }
}

Status DatabasePlugin::reset() {
  tearDown();
  return setUp();
}

bool DatabasePlugin::checkDB() {
  kCheckingDB = true;
  bool result = true;
  try {
    auto status = setUp();
    if (kDBHandleOptionRequireWrite && read_only_) {
      result = false;
    }
    tearDown();
    result = status.ok();
  } catch (const std::exception& e) {
    VLOG(1) << "Database plugin check failed: " << e.what();
    result = false;
  }
  kCheckingDB = false;
  return result;
}

Status DatabasePlugin::call(const PluginRequest& request,
                            PluginResponse& response) {
  if (request.count("action") == 0) {
    return Status(1, "Database plugin must include a request action");
  }

  // Get a domain/key, which are used for most database plugin actions.
  auto domain = (request.count("domain") > 0) ? request.at("domain") : "";
  auto key = (request.count("key") > 0) ? request.at("key") : "";

  // Switch over the possible database plugin actions.
  if (request.at("action") == "get") {
    std::string value;
    auto status = this->get(domain, key, value);
    response.push_back({{"v", value}});
    return status;
  } else if (request.at("action") == "put") {
    if (request.count("value") == 0) {
      return Status(1, "Database plugin put action requires a value");
    }
    return this->put(domain, key, request.at("value"));
  } else if (request.at("action") == "remove") {
    return this->remove(domain, key);
  } else if (request.at("action") == "scan") {
    // Accumulate scanned keys into a vector.
    std::vector<std::string> keys;
    // Optionally allow the caller to request a max number of keys.
    size_t max = 0;
    if (request.count("max") > 0) {
      max = std::stoul(request.at("max"));
    }
    auto status = this->scan(domain, keys, request.at("prefix"), max);
    for (const auto& key : keys) {
      response.push_back({{"k", key}});
    }
    return status;
  }

  return Status(1, "Unknown database plugin action");
}

static inline std::shared_ptr<DatabasePlugin> getDatabasePlugin() {
  if (!Registry::exists("database", Registry::getActive("database"), true)) {
    return nullptr;
  }

  auto plugin = Registry::get("database", Registry::getActive("database"));
  return std::dynamic_pointer_cast<DatabasePlugin>(plugin);
}

Status getDatabaseValue(const std::string& domain,
                        const std::string& key,
                        std::string& value) {
  if (Registry::external()) {
    // External registries (extensions) do not have databases active.
    // It is not possible to use an extension-based database.
    PluginRequest request = {
        {"action", "get"}, {"domain", domain}, {"key", key}};
    PluginResponse response;
    auto status = Registry::call("database", request, response);
    if (status.ok()) {
      // Set value from the internally-known "v" key.
      if (response.size() > 0 && response[0].count("v") > 0) {
        value = response[0].at("v");
      }
    }
    return status;
  } else {
    auto plugin = getDatabasePlugin();
    return plugin->get(domain, key, value);
  }
}

Status setDatabaseValue(const std::string& domain,
                        const std::string& key,
                        const std::string& value) {
  if (Registry::external()) {
    // External registries (extensions) do not have databases active.
    // It is not possible to use an extension-based database.
    PluginRequest request = {
        {"action", "put"}, {"domain", domain}, {"key", key}, {"value", value}};
    return Registry::call("database", request);
  } else {
    auto plugin = getDatabasePlugin();
    return plugin->put(domain, key, value);
  }
}

Status deleteDatabaseValue(const std::string& domain, const std::string& key) {
  if (Registry::external()) {
    // External registries (extensions) do not have databases active.
    // It is not possible to use an extension-based database.
    PluginRequest request = {
        {"action", "remove"}, {"domain", domain}, {"key", key}};
    return Registry::call("database", request);
  } else {
    auto plugin = getDatabasePlugin();
    return plugin->remove(domain, key);
  }
}

Status scanDatabaseKeys(const std::string& domain,
                        std::vector<std::string>& keys,
                        size_t max) {
  return scanDatabaseKeys(domain, keys, "", max);
}

/// Get a list of keys for a given domain.
Status scanDatabaseKeys(const std::string& domain,
                        std::vector<std::string>& keys,
                        const std::string& prefix,
                        size_t max) {
  if (Registry::external()) {
    // External registries (extensions) do not have databases active.
    // It is not possible to use an extension-based database.
    PluginRequest request = {{"action", "scan"},
                             {"domain", domain},
                             {"prefix", prefix},
                             {"max", std::to_string(max)}};
    PluginResponse response;
    auto status = Registry::call("database", request, response);

    for (const auto& item : response) {
      if (item.count("k") > 0) {
        keys.push_back(item.at("k"));
      }
    }
    return status;
  } else {
    auto plugin = getDatabasePlugin();
    return plugin->scan(domain, keys, prefix, max);
  }
}

void dumpDatabase() {
  for (const auto& domain : kDomains) {
    std::vector<std::string> keys;
    if (!scanDatabaseKeys(domain, keys)) {
      continue;
    }
    for (const auto& key : keys) {
      std::string value;
      if (!getDatabaseValue(domain, key, value)) {
        continue;
      }
      fprintf(
          stdout, "%s[%s]: %s\n", domain.c_str(), key.c_str(), value.c_str());
    }
  }
}
}
