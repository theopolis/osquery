# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(zstdMain)
  set(name "zstd")
  set(version "1.2.0")

  set(anchor_file "lib/libzstd.a")

  if(DEFINED PLATFORM_LINUX)
    set(hash "067cb5d0648c5f32b6ca1303e0ebcaa67263cfaf76347d943ff73e9ee488f4db")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "4cd66f8c05f735ccf6c1457116ddb4cb2b1b0260458bb3c1476475721c9d70d9")
  elseif(DEFINED PLATFORM_WINDOWS)
    set(hash "c214705dfd057b2e9b9e613c88131ccfde22c2f43787af37828ccf3f9bec918d")
    set(anchor_file "lib/libzstd.lib")
  else()
    return()
  endif()

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

zstdMain()
