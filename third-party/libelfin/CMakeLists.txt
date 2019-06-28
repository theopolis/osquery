# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libelfinMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libelfin")
  set(version "0.3")
  set(hash "13a13d78f0989e150a762c358243fa315dc132896d0305dc1220c93c4647717d")
  set(anchor_file "lib/libdwarf++.a")

  set(additional_lib
    lib/libelf++.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_lib})
endfunction()

libelfinMain()
