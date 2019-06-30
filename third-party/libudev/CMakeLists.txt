# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libudevMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libudev")
  set(anchor_file "lib/libudev.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  definePrebuildProject(${name}
    URL http://pkgs.fedoraproject.org/repo/pkgs/udev/udev-173.tar.bz2/91a88a359b60bbd074b024883cc0dbde/udev-173.tar.bz2
    SHA256 70a18315a12f8fc1131f7da5b4dae3606988b69d5c08f96f443b84b8486caaaf
    CONFIGURE
      ./configure --prefix=<INSTALL_DIR>
        --disable-logging
        --disable-rule_generator
        --disable-introspection
        --disable-gudev
        --disable-keymap
        --disable-mtd-probe
        --disable-hwdb
        --disable-shared
        --enable-static
        --enable-gtk-doc-html=no
        --with-systemdsystemunitdir=<INSTALL_DIR>/share
    BUILD
      $(MAKE) libudev/libudev.la
    INSTALL
      $(MAKE) install-exec &&
      $(MAKE) install-includeHEADERS
    BUILD_IN_SOURCE ON
  )
endfunction()

libudevMain()
