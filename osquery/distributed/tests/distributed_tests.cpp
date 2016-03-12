/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <iostream>

#include <gtest/gtest.h>

#include <osquery/core.h>
#include <osquery/distributed.h>
#include <osquery/enroll.h>
#include <osquery/sql.h>

#include "osquery/core/test_util.h"
#include "osquery/sql/sqlite_util.h"

DECLARE_string(distributed_tls_read_endpoint);
DECLARE_string(distributed_tls_write_endpoint);

namespace osquery {

class DistributedTests : public testing::Test {
 protected:
  void SetUp() {
    TLSServerRunner::start();
    TLSServerRunner::setClientConfig();
    clearNodeKey();

    distributed_tls_read_endpoint_ =
        Flag::getValue("distributed_tls_read_endpoint");
    Flag::updateValue("distributed_tls_read_endpoint", "/distributed_read");

    distributed_tls_write_endpoint_ =
        Flag::getValue("distributed_tls_write_endpoint");
    Flag::updateValue("distributed_tls_write_endpoint", "/distributed_write");

    Registry::setActive("distributed", "tls");
  }

  void TearDown() {
    TLSServerRunner::stop();
    TLSServerRunner::unsetClientConfig();
    clearNodeKey();

    Flag::updateValue("distributed_tls_read_endpoint",
                      distributed_tls_read_endpoint_);
    Flag::updateValue("distributed_tls_write_endpoint",
                      distributed_tls_write_endpoint_);
  }

 protected:
  std::string distributed_tls_read_endpoint_;
  std::string distributed_tls_write_endpoint_;
};

TEST_F(DistributedTests, test_serialize_distributed_query_request) {
  DistributedQueryRequest r;
  r.query = "foo";
  r.id = "bar";

  Json::Value tree;
  auto s = serializeDistributedQueryRequest(r, tree);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(tree["query"], "foo");
  EXPECT_EQ(tree["id"], "bar");
}

TEST_F(DistributedTests, test_deserialize_distributed_query_request) {
  Json::Value tree;
  tree["query"] = "foo";
  tree["id"] = "bar";

  DistributedQueryRequest r;
  auto s = deserializeDistributedQueryRequest(tree, r);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(r.query, "foo");
  EXPECT_EQ(r.id, "bar");
}

TEST_F(DistributedTests, test_deserialize_distributed_query_request_json) {
  auto json =
      "{"
      "  \"query\": \"foo\","
      "  \"id\": \"bar\""
      "}";

  DistributedQueryRequest r;
  auto s = deserializeDistributedQueryRequestJSON(json, r);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(r.query, "foo");
  EXPECT_EQ(r.id, "bar");
}

TEST_F(DistributedTests, test_serialize_distributed_query_result) {
  DistributedQueryResult r;
  r.request.query = "foo";
  r.request.id = "bar";

  Row r1;
  r1["foo"] = "bar";
  r.results = {r1};

  Json::Value tree;
  auto s = serializeDistributedQueryResult(r, tree);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(tree["request.query"], "foo");
  EXPECT_EQ(tree["request.id"], "bar");
  auto& results = tree["results"];
  for (const auto& q : results) {
    for (auto it = q.begin(); it != q.end(); it++) {
      EXPECT_EQ(it.name(), "foo");
      EXPECT_EQ(it->asString(), "bar");
    }
  }
}

TEST_F(DistributedTests, test_deserialize_distributed_query_result) {
  Json::Value request;
  request["id"] = "foo";
  request["query"] = "bar";

  Json::Value row;
  row["foo"] = "bar";
  Json::Value results;
  results.append(row);

  Json::Value query_result;
  query_result["request"] = request;
  query_result["results"] = results;

  DistributedQueryResult r;
  auto s = deserializeDistributedQueryResult(query_result, r);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(r.request.id, "foo");
  EXPECT_EQ(r.request.query, "bar");
  EXPECT_EQ(r.results[0]["foo"], "bar");
}

TEST_F(DistributedTests, test_deserialize_distributed_query_result_json) {
  auto json =
      "{"
      "  \"request\": {"
      "    \"id\": \"foo\","
      "    \"query\": \"bar\""
      "  },"
      "  \"results\": ["
      "    {"
      "      \"foo\": \"bar\""
      "    }"
      "  ]"
      "}";

  DistributedQueryResult r;
  auto s = deserializeDistributedQueryResultJSON(json, r);
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(r.request.id, "foo");
  EXPECT_EQ(r.request.query, "bar");
  EXPECT_EQ(r.results[0]["foo"], "bar");
}

TEST_F(DistributedTests, test_workflow) {
  auto dist = Distributed();
  auto s = dist.pullUpdates();
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(s.toString(), "OK");

  EXPECT_EQ(dist.getPendingQueryCount(), 2U);
  EXPECT_EQ(dist.results_.size(), 0U);
  s = dist.runQueries();
  EXPECT_TRUE(s.ok());
  EXPECT_EQ(s.toString(), "OK");

  EXPECT_EQ(dist.getPendingQueryCount(), 0U);
  EXPECT_EQ(dist.results_.size(), 2U);
}
}
