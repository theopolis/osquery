# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(lldpdMain)
  set(name "lldpd")
  set(version "0.9.6")

  if(DEFINED PLATFORM_LINUX)
    set(hash "b4ffbd0a96ddb3f151cfedfb30538f58ec06453c61ca5ea748e59056f94c1d03")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "f9d5d5c0c2514e7d51914ffc747a068b8a82602ca62e44b65f02857f015e0d3f")
  else()
    return()
  endif()

  set(anchor_file "lib/liblldpctl.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

lldpdMain()
