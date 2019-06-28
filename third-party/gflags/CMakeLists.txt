# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(gflagsMain)
  set(name "gflags")
  set(version "2.2.1")

  set(anchor_file "lib/libgflags.a")

  set(additional_library
    lib/libgflags_nothreads.a
  )

  if(DEFINED PLATFORM_LINUX)
    set(hash "e8183a770f80c1d31bacd74bfcb016fe025eae9b78268cab3b5b833f3f809606")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "217fd2573443981bc8e521fcf4d8201ba4d3c29cace1b9a537f94be08df7ebb6")
  elseif(DEFINED PLATFORM_WINDOWS)
    set(hash "a7bb0676d7ac0338cfa71f48f5e0d83332470e1fcd0223aa697f1a0fd2e0789a")

    set(anchor_file "lib/gflags_static.lib")
    set(additional_library "")

  else()
    return()
  endif()

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_library})
endfunction()

gflagsMain()
