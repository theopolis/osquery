# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(librpmMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "librpm")
  set(version "4.14.1")
  set(hash "2461ef466cc70642f5da69fb89ffb181f5313c171a92907b172aa8536a155f68")
  set(anchor_file "lib/librpm.a")

  set(additional_libraries
    lib/librpmbuild.a
    lib/librpmio.a
    lib/librpmsign.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_libraries})

  target_link_libraries("thirdparty_${name}" INTERFACE
    thirdparty_berkeley-db
    thirdparty_bzip2
    thirdparty_openssl
    thirdparty_popt
    thirdparty_xz
    thirdparty_zlib
  )

  target_link_libraries("thirdparty_${name}_librpm" INTERFACE
    "thirdparty_${name}_librpmio"
  )

  target_link_libraries("thirdparty_${name}_librpmio" INTERFACE thirdparty_zlib)
endfunction()

librpmMain()
