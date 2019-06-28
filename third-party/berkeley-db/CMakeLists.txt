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
  set(version "5.3.28")
  set(hash "b1b61fbb9d4298c9ca09f835cde68bf3ed40fc466e23ee52691c9a8a481d52c0")
  set(anchor_file "lib/libdb.a")

  set(additional_libraries
    lib/libdb-5.3.a
    lib/libdb_cxx-5.3.a
    lib/libdb_cxx.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_libraries})

endfunction()

berkeleydbMain()
