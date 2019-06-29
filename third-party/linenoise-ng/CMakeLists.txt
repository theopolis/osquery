# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(linenoisengMain)
  set(name "linenoise-ng")

  set(anchor_file "lib/liblinenoise.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/linenoise.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

linenoisengMain()
