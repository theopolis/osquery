# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libdevmapperMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libdevmapper")
  set(version "2.2.02.173")
  set(hash "5cfe6dfd2d7ca764433a55f9a7ac3da52c0769ec6c6f1b9ec9be4bb2b9154e42")
  set(anchor_file "lib/liblvm2app.a")

  set(additional_libraries
    lib/liblvm-internal.a
    lib/libdevmapper.a
    lib/libdaemonclient.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_libraries})
endfunction()

libdevmapperMain()
