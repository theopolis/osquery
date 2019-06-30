# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(gflagsMain)
  set(name "gflags")

  set(anchor_file "lib/libgflags.a")

  set(additional_library
    lib/libgflags_nothreads.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/gflags_static.lib")
    set(additional_library "")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_library})

  definePrebuildProject(${name}
    URL https://github.com/gflags/gflags/archive/v2.2.1.tar.gz
    SHA256 ae27cdbcd6a2f935baa78e4f21f675649271634c092b1be01469440495609d0e
    CONFIGURE
      cmake
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_SHARED_LIBS=OFF
        <SOURCE_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
  )
endfunction()

gflagsMain()
