/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <gmock/gmock.h>
#include <gtest/gtest.h>

#include <osquery/core.h>

#include "osquery/core/testing.h"
#include "osquery/core/watcher.h"

using namespace testing;

namespace osquery {

class WatcherTests : public testing::Test {};

class MockWatcherRunner : public WatcherRunner {
 public:
  MockWatcherRunner() : WatcherRunner(0, nullptr, false) {}

  MOCK_CONST_METHOD1(stopChild, void(const PlatformProcess& child));
  MOCK_CONST_METHOD1(isChildSane, Status(const PlatformProcess& child));
  MOCK_METHOD1(createExtension, bool(const std::string& extension));
  MOCK_METHOD0(createWorker, void());

 private:
  FRIEND_TEST(WatcherTests, test_watcher);
};

class FakePlatformProcess : public PlatformProcess {
 public:
  FakePlatformProcess(PlatformPidType id) : PlatformProcess(id) {}

  ProcessState checkStatus(int& s) const {
    s = 0;
    return PROCESS_STILL_ALIVE;
  }
};

TEST_F(WatcherTests, test_watcher) {
  MockWatcherRunner runner;

  // Create a fake test process.
  auto test_process = PlatformProcess::getCurrentProcess();
  auto fake_test_process = FakePlatformProcess(test_process->pid());

  EXPECT_CALL(runner, isChildSane(_)).Times(1).WillOnce(Return(Status(0)));
  EXPECT_CALL(runner, stopChild(_)).Times(0);

  EXPECT_TRUE(runner.watch(fake_test_process));
}

// Later provide a FakeWatcherRunner:

/**
 * @brief What the runner's internals will use as process state.
 *
 * Internal calls to getProcessRow will return this structure.
 */
/*
  void setProcessRow(QueryData qd) { qd_ = std::move(qd); }

  /// The tests do not have access to the processes table.
  QueryData getProcessRow(pid_t pid) const { return qd_; }

 private:
  QueryData qd_;
*/
}
