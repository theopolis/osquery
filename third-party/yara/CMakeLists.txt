# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(yaraMain)
  if(DEFINED PLATFORM_WINDOWS)
    return()
  endif()

  set(name "yara")
  set(anchor_file "lib/libyara.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_openssl)
endfunction()

yaraMain()
