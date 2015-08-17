/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <gtest/gtest.h>

#include <osquery/filesystem.h>

#include "osquery/core/test_util.h"
#include "osquery/tables/other/yara_utils.h"

namespace osquery {

const std::string ls = "/bin/ls";
const std::string alwaysTrue = "rule always_true { condition: true }";
const std::string alwaysFalse = "rule always_false { condition: false }";

class YARATest : public testing::Test {
 protected:
  void SetUp() {
    rule_file_ = kTestWorkingDirectory + "/osquery-yara.sig";
    remove(rule_file_);
    if (pathExists(rule_file_).ok()) {
      throw std::domain_error("YARA rule file exists: " + rule_file_ + ".");
    }
  }

  void TearDown() { remove(rule_file_); }

  Row scanFile(const std::string& ruleContent) {
    YR_RULES* rules = nullptr;
    // Make sure YARA initialized.
    int result = yr_initialize();
    EXPECT_TRUE(result == ERROR_SUCCESS);

    // Write the required rule to our temporary files.
    writeTextFile(rule_file_, ruleContent);

    // Compile those rules (slow).
    Status status = compileSingleFile(rule_file_, &rules);
    EXPECT_TRUE(status.ok());

    Row r;
    r["count"] = "0";
    r["matches"] = "";

    // Apply the compiled rules to a pre-determined binary.
    result = yr_rules_scan_file(rules,
                                ls.c_str(),
                                SCAN_FLAGS_FAST_MODE,
                                YARACallback,
                                (void*)&r,
                                0);
    // Expect that the rule compiled and was applied without error.
    // This does NOT mean anything related to the rule content/success/matching.
    EXPECT_TRUE(result == ERROR_SUCCESS);

    yr_rules_destroy(rules);
    return r;
  }

 private:
  std::string rule_file_;
};

TEST_F(YARATest, test_match_true) {
  Row r = scanFile(alwaysTrue);
  // Should have 1 count, this rule will match.
  EXPECT_TRUE(r["count"] == "1");
}

TEST_F(YARATest, test_match_false) {
  Row r = scanFile(alwaysFalse);
  // Should have 0 count, this rule will NOT match.
  EXPECT_TRUE(r["count"] == "0");
}
}
