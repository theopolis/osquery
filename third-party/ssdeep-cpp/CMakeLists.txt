# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(ssdeepCppMain)
  set(name "ssdeep-cpp")

  if(DEFINED PLATFORM_WINDOWS)
    add_osquery_library(thirdparty_ssdeep-cpp INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libfuzzy.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

ssdeepCppMain()
