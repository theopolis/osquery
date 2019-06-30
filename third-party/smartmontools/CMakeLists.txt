# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(smartmontoolsMain)
  set(name "smartmontools")

  if(DEFINED PLATFORM_WINDOWS)
    return()
  endif()

  set(anchor_file "lib/libsmartctl.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  definePrebuildProject(${name}
    URL https://github.com/allanliu/smartmontools/archive/v0.3.1.tar.gz
    SHA256
    CONFIGURE
      ${REPLACE_CMD} "1.15 1.14" "1.16 1.15 1.14" "autogen.sh" &&
      ./autogen.sh &&
      ./configure
        --prefix=<INSTALL_DIR>
        --disable-shared
        --enable-static
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
    BUILD_IN_SOURCE ON
  )
endfunction()

smartmontoolsMain()
