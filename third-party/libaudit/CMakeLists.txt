# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libauditMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libaudit")
  set(anchor_file "lib/libaudit.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  definePrebuildProject(${name}
    URL https://github.com/Distrotech/libaudit/archive/audit-2.4.2.tar.gz
    SHA256
    CONFIGURE
      ./configure
        --prefix=<INSTALL_DIR>
        --disable-shared
        --enable-static
    BUILD
      cd lib && $(MAKE)
    INSTALL
      cd lib && $(MAKE) install
    BUILD_IN_SOURCE ON
  )
endfunction()

libauditMain()
