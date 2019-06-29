# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(zlibMain)
  set(name "zlib")
  set(anchor_file "lib/libz.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/zlibstatic.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

zlibMain()
