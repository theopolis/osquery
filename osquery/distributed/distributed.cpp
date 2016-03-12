/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <sstream>
#include <utility>

#include <json/reader.h>
#include <json/writer.h>

#include <osquery/core.h>
#include <osquery/distributed.h>
#include <osquery/logger.h>
#include <osquery/sql.h>

namespace osquery {

FLAG(string, distributed_plugin, "tls", "Distributed plugin name");

FLAG(bool,
     disable_distributed,
     true,
     "Disable distributed queries (default true)");

Mutex distributed_queries_mutex_;
Mutex distributed_results_mutex_;

Status DistributedPlugin::call(const PluginRequest& request,
                               PluginResponse& response) {
  if (request.count("action") == 0) {
    return Status(1, "Distributed plugins require an action in PluginRequest");
  }

  if (request.at("action") == "getQueries") {
    std::string queries;
    getQueries(queries);
    response.push_back({{"results", queries}});
    return Status(0, "OK");
  } else if (request.at("action") == "writeResults") {
    if (request.count("results") == 0) {
      return Status(1, "Missing results field");
    }
    return writeResults(request.at("results"));
  }

  return Status(1,
                "Distributed plugin action unknown: " + request.at("action"));
}

Status Distributed::pullUpdates() {
  auto& distributed_plugin = Registry::getActive("distributed");
  if (!Registry::exists("distributed", distributed_plugin)) {
    return Status(1, "Missing distributed plugin: " + distributed_plugin);
  }

  PluginResponse response;
  auto status =
      Registry::call("distributed", {{"action", "getQueries"}}, response);
  if (!status.ok()) {
    return status;
  }

  if (response.size() > 0 && response[0].count("results") > 0) {
    return acceptWork(response[0]["results"]);
  }

  return Status(0, "OK");
}

size_t Distributed::getPendingQueryCount() {
  WriteLock lock(distributed_queries_mutex_);
  return queries_.size();
}

size_t Distributed::getCompletedCount() {
  WriteLock lock(distributed_results_mutex_);
  return results_.size();
}

Status Distributed::serializeResults(std::string& json) {
  Json::Value tree;
  {
    WriteLock lock(distributed_results_mutex_);
    for (const auto& result : results_) {
      Json::Value qd;
      auto s = serializeQueryData(result.results, qd);
      if (!s.ok()) {
        return s;
      }
      tree[result.request.id] = qd;
    }
  }

  Json::Value results;
  results["queries"] = tree;

  Json::FastWriter writer;
  json = writer.write(results);
  return Status(0, "OK");
}

void Distributed::addResult(const DistributedQueryResult& result) {
  WriteLock wlock_results(distributed_results_mutex_);
  results_.push_back(result);
}

Status Distributed::runQueries() {
  while (getPendingQueryCount() > 0) {
    auto query = popRequest();

    auto sql = SQL(query.query);
    if (!sql.getStatus().ok()) {
      LOG(ERROR) << "Error running distributed query[" << query.id
                 << "]: " << query.query;
      continue;
    }

    DistributedQueryResult result(std::move(query), std::move(sql.rows()));
    addResult(result);
  }
  return flushCompleted();
}

Status Distributed::flushCompleted() {
  if (getCompletedCount() == 0) {
    return Status(0, "OK");
  }

  auto& distributed_plugin = Registry::getActive("distributed");
  if (!Registry::exists("distributed", distributed_plugin)) {
    return Status(1, "Missing distributed plugin " + distributed_plugin);
  }

  std::string results;
  auto s = serializeResults(results);
  if (!s.ok()) {
    return s;
  }

  PluginResponse response;
  return Registry::call("distributed",
                        {{"action", "writeResults"}, {"results", results}},
                        response);
}

Status Distributed::acceptWork(const std::string& work) {
  Json::Value tree;
  Json::Reader reader;

  if (!reader.parse(work, tree, false)) {
    return Status(1, "Error parsing JSON");
  }

  auto& queries = tree["queries"];
  for (auto it = queries.begin(); it != queries.end(); it++) {
    DistributedQueryRequest request;
    request.id = it.name();
    request.query = it->asString();
    if (request.query.empty() || request.id.empty()) {
      return Status(1, "Distributed query does not have complete attributes.");
    }
    WriteLock wlock(distributed_queries_mutex_);
    queries_.push_back(request);
  }

  return Status(0, "OK");
}

DistributedQueryRequest Distributed::popRequest() {
  WriteLock wlock_queries(distributed_queries_mutex_);
  auto q = queries_[0];
  queries_.erase(queries_.begin());
  return q;
}

Status serializeDistributedQueryRequest(const DistributedQueryRequest& r,
                                        Json::Value& tree) {
  tree["query"] = r.query;
  tree["id"] = r.id;
  return Status(0, "OK");
}

Status serializeDistributedQueryRequestJSON(const DistributedQueryRequest& r,
                                            Json::Value& json) {
  Json::Value tree;
  auto s = serializeDistributedQueryRequest(r, tree);
  if (!s.ok()) {
    return s;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

Status deserializeDistributedQueryRequest(const Json::Value& tree,
                                          DistributedQueryRequest& r) {
  r.query = tree["query"].asString();
  r.id = tree["id"].asString();
  return Status(0, "OK");
}

Status deserializeDistributedQueryRequestJSON(const std::string& json,
                                              DistributedQueryRequest& r) {
  Json::Value tree;
  Json::Reader reader;

  if (!reader.parse(json, tree, false)) {
    return Status(1, "Error serializing JSON");
  }
  return deserializeDistributedQueryRequest(tree, r);
}

/////////////////////////////////////////////////////////////////////////////
// DistributedQueryResult - small struct containing the results of a
// distributed query
/////////////////////////////////////////////////////////////////////////////

Status serializeDistributedQueryResult(const DistributedQueryResult& r,
                                       Json::Value& tree) {
  Json::Value request;
  auto s = serializeDistributedQueryRequest(r.request, request);
  if (!s.ok()) {
    return s;
  }

  Json::Value results;
  s = serializeQueryData(r.results, results);
  if (!s.ok()) {
    return s;
  }

  tree["request"] = request;
  tree["results"] = results;
  return Status(0, "OK");
}

Status serializeDistributedQueryResultJSON(const DistributedQueryResult& r,
                                           std::string& json) {
  Json::Value tree;
  auto s = serializeDistributedQueryResult(r, tree);
  if (!s.ok()) {
    return s;
  }

  Json::FastWriter writer;
  json = writer.write(tree);
  return Status(0, "OK");
}

Status deserializeDistributedQueryResult(const Json::Value& tree,
                                         DistributedQueryResult& r) {
  DistributedQueryRequest request;
  auto s = deserializeDistributedQueryRequest(tree["request"], request);
  if (!s.ok()) {
    return s;
  }

  QueryData results;
  s = deserializeQueryData(tree["results"], results);
  if (!s.ok()) {
    return s;
  }

  r.request = request;
  r.results = results;
  return Status(0, "OK");
}

Status deserializeDistributedQueryResultJSON(const std::string& json,
                                             DistributedQueryResult& r) {
  Json::Value tree;
  Json::Reader reader;

  if (!reader.parse(json, tree, false)) {
    return Status(1, "Error serializing JSON");
  }
  return deserializeDistributedQueryResult(tree, r);
}
}
