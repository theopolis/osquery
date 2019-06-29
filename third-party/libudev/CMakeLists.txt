# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libudevMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libudev")
  set(anchor_file "lib/libudev.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

libudevMain()
