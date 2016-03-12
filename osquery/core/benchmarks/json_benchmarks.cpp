/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <benchmark/benchmark.h>

#include <json/json.h>
#include <json/reader.h>
#include <json/writer.h>

#include <osquery/filesystem.h>

#include "osquery/core/conversions.h"
#include "osquery/core/test_util.h"

namespace osquery {

static void JSON_accesses(benchmark::State& state) {
  std::string content;
  readFile(kTestDataPath + "test_inline_pack.conf", content);

  Json::Value root;
  std::stringstream input;
  input << content;
  input >> root;

  while (state.KeepRunning()) {
    for (auto& item : root) {
      auto value = item["item"].asString();
    }
  }
}

BENCHMARK(JSON_accesses);

static void JSON_read_string(benchmark::State& state) {
  auto data = getTestConfigMap()["awesome"];

  while (state.KeepRunning()) {
    Json::Value root;
    std::stringstream input;
    input << data;
    input >> root;
  }
}

BENCHMARK(JSON_read_string);

static void JSON_write_string(benchmark::State& state) {
  auto data = getTestConfigMap()["awesome"];

  Json::Value root;
  std::stringstream input;
  input << data;
  input >> root;

  while (state.KeepRunning()) {
    Json::FastWriter fw;
    auto out = fw.write(root);
  }
}

BENCHMARK(JSON_write_string);
}
