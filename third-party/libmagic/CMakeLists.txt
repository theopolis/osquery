# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libmagicMain)
  set(name "libmagic")
  set(version "5.32")

  if(DEFINED PLATFORM_LINUX)
    set(hash "0589182832e5e9cbebfe993cabacccfd0e6129c3a25c20a5d0b35be1e3eeca3f")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "66efdaf945b8d04751aa337ef0529ded53fcd7e3b85fb8dfd9e4c40a562ffa6d")
  else()
    add_osquery_library(thirdparty_libmagic INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libmagic.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_zlib)
endfunction()

libmagicMain()
