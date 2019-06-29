# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(berkeleydbMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "berkeley-db")
  set(anchor_file "lib/libdb.a")

  set(additional_libraries
    lib/libdb-5.3.a
    lib/libdb_cxx-5.3.a
    lib/libdb_cxx.a
  )

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})
endfunction()

berkeleydbMain()
