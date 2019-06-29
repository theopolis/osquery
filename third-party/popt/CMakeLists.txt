# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(poptMain)
  set(name "popt")

  if(DEFINED PLATFORM_WINDOWS)
    return()
  endif()

  set(anchor_file "lib/libpopt.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

poptMain()
