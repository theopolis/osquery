# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13.3)
include("${CMAKE_CURRENT_LIST_DIR}/utils.cmake")

importSourceSubmodule(
  NAME "aws-sdk-cpp"

  SUBMODULES
    "aws-c-common_src"
    "aws-c-event-stream_src"
    "aws-checksums_src"
    "aws-sdk-cpp_src"
)
