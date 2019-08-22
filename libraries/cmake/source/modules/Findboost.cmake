# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13.3)
include("${CMAKE_CURRENT_LIST_DIR}/utils.cmake")

importSourceSubmodule(
  NAME "boost"

  NO_RECURSIVE SUBMODULES
    "src"
    "src/libs/serialization"
    "src/libs/numeric/conversion"
    "src/libs/random"
    "src/libs/${folder_name}"
    "src/libs/locale"
    "src/libs/exception"
    "src/libs/chrono"
    "src/libs/math"
    "src/libs/container"
    "src/libs/date_time"
    "src/libs/context"
    "src/libs/coroutine"
    "src/libs/filesystem"
    "src/libs/regex"
    "src/libs/atomic"
    "src/libs/thread"
)
