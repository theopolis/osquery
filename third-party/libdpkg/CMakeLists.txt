# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libdpkgMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libdpkg")
  set(version "1.19.0.5")
  set(hash "a3775b2cbf9787875f94329066e2950185e80a9a5474db2f84ff7a19186c6bc9")
  set(anchor_file "lib/libdpkg.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_zlib)
endfunction()

libdpkgMain()
