# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(boostMain)
  set(name "boost")
  set(anchor_file "lib/libboost_chrono-mt.a")

  set(additional_libraries
    lib/libboost_context-mt.a
    lib/libboost_coroutine-mt.a
    lib/libboost_filesystem-mt.a
    lib/libboost_regex-mt.a
    lib/libboost_thread-mt.a
    lib/libboost_system-mt.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libboost_chrono-mt-s.lib")

    set(additional_libraries
      lib/libboost_context-mt-s.lib
      lib/libboost_coroutine-mt-s.lib
      lib/libboost_filesystem-mt-s.lib
      lib/libboost_regex-mt-s.lib
      lib/libboost_thread-mt-s.lib
      lib/libboost_system-mt-s.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})
endfunction()

boostMain()
