# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(glogMain)
  set(name "glog")
  set(anchor_file "lib/libglog.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/glog.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_gflags)

  set(dependencies gflags)
  definePrebuildProject(${name}
    URL https://github.com/google/glog/archive/v0.3.5.tar.gz
    SHA256
    DEPENDS ${dependencies}
    CONFIGURE
      cmake
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DBUILD_SHARED_LIBS=OFF
        -DBUILD_TESTING=OFF
        <SOURCE_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
  )
endfunction()

glogMain()
