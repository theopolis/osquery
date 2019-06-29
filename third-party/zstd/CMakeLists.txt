# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(zstdMain)
  set(name "zstd")
  set(anchor_file "lib/libzstd.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libzstd.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

zstdMain()
