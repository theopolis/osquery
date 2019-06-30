# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(bzip2Main)
  set(name "bzip2")
  set(anchor_file "lib/libbz2.a")

  if(DEFINED PLATFORM_MACOS)
    add_osquery_library(thirdparty_bzip2 INTERFACE)
    target_link_libraries(thirdparty_bzip2 INTERFACE "bz2")
    return()
  elseif(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libbz2.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  definePrebuildProject(${name}
    URL http://http.debian.net/debian/pool/main/b/bzip2/bzip2_1.0.6.orig.tar.bz2
    SHA256
    DEPENDS ${dependencies}
    CONFIGURE
      ${REPLACE_CMD} "CFLAGS=" "CFLAGS=$ENV{CFLAGS} " Makefile &&
      ${REPLACE_CMD} "CC=gcc" "CC=$ENV{CC}" Makefile
    BUILD true
    INSTALL
      $(MAKE) install PREFIX=<INSTALL_DIR>
    BUILD_IN_SOURCE ON
  )
endfunction()

bzip2Main()
