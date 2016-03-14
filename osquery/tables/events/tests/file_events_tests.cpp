/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <json/writer.h>

#include <gtest/gtest.h>

#include <osquery/config.h>
#include <osquery/events.h>
#include <osquery/flags.h>
#include <osquery/logger.h>
#include <osquery/registry.h>
#include <osquery/sql.h>

#include "osquery/core/test_util.h"
#include "osquery/tables/events/event_utils.h"

namespace osquery {

DECLARE_bool(registry_exceptions);

class FileEventSubscriber;

class FileEventsTableTests : public testing::Test {
 public:
  void SetUp() override {
    Config::getInstance().reset();

    // Promote registry access exceptions when testing tables and SQL.
    exceptions_ = FLAGS_registry_exceptions;
    FLAGS_registry_exceptions = true;

    // Setup configuration parsers for file paths accesses.
    Registry::registry("config_parser")->setUp();
  }

  void TearDown() override { FLAGS_registry_exceptions = exceptions_; }

 protected:
  Status load() { return Config::getInstance().load(); }

 private:
  bool exceptions_{false};
};

TEST_F(FileEventsTableTests, test_subscriber_exists) {
  ASSERT_TRUE(Registry::exists("event_subscriber", "file_events"));

  // Note: do not perform a reinterpret cast like this.
  auto plugin = Registry::get("event_subscriber", "file_events");
  auto* subscriber =
      reinterpret_cast<std::shared_ptr<FileEventSubscriber>*>(&plugin);
  EXPECT_NE(subscriber, nullptr);
}

TEST_F(FileEventsTableTests, test_table_empty) {
  // Attach/create the publishers.
  attachEvents();

  auto results = SQL::selectAllFrom("file_events");
  EXPECT_EQ(results.size(), 0U);
}

class FileEventsTestsConfigPlugin : public ConfigPlugin {
 public:
  Status genConfig(std::map<std::string, std::string>& config) override {
    Json::FastWriter writer;
    config["data"] = writer.write(getUnrestrictedPack());
    return Status(0);
  }
};

TEST_F(FileEventsTableTests, test_configure_subscriptions) {
  // Attach/create the publishers.
  attachEvents();

  // Load a configuration with file paths, verify subscriptions.
  Registry::add<FileEventsTestsConfigPlugin>("config", "file_events_tests");
  Registry::setActive("config", "file_events_tests");
  this->load();

  // Explicitly request a configure for subscribers.
  Registry::registry("event_subscriber")->configure();

  std::string q = "select * from osquery_events where name = 'file_events'";
  auto results = SQL(q);
  ASSERT_EQ(results.rows().size(), 1U);
  auto& row = results.rows()[0];
  // Expect the paths within "unrestricted_pack" to be created as subscriptions.
  EXPECT_EQ(row.at("subscriptions"), "2");

  // The most important part, make sure a reconfigure removes the subscriptions.
  Config::getInstance().update({{"data", "{}"}});
  results = SQL(q);
  auto& row2 = results.rows()[0];
  EXPECT_EQ(row2.at("subscriptions"), "0");
}
}
