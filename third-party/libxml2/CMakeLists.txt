# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libxml2Main)
  set(name "libxml2")

  if(DEFINED PLATFORM_WINDOWS)
    add_osquery_library(thirdparty_libxml2 INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libxml2.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_zlib)
endfunction()

libxml2Main()
