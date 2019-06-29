# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(utillinuxMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "util-linux")
  set(anchor_file "lib/libuuid.a")

  set(additional_libraries
    lib/libblkid.a
  )

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})
endfunction()

utillinuxMain()
