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

#include <osquery/database.h>

#include "osquery/tests/test_util.h"

int main(int argc, char *argv[]) {
  osquery::initTesting(false);
  ::benchmark::Initialize(&argc, argv);
  ::benchmark::RunSpecifiedBenchmarks();
  // Optionally enable Goggle Logging
  // google::InitGoogleLogging(argv[0]);
  return 0;
}
