# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(gflagsMain)
  set(name "gflags")

  set(anchor_file "lib/libgflags.a")

  set(additional_library
    lib/libgflags_nothreads.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/gflags_static.lib")
    set(additional_library "")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_library})
endfunction()

gflagsMain()
