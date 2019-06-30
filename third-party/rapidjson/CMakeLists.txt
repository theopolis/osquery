# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(rapidjsonMain)
  set(name "rapidjson")
  set(anchor_file "include/rapidjson/rapidjson.h")

  importThirdPartyHeaderOnlyLibrary("PREBUILT" "${name}" "${anchor_file}" "include")

  definePrebuildProject(${name}
    URL https://github.com/miloyip/rapidjson/archive/v1.1.0.tar.gz
    SHA256
    PATCHES librapidjson-1.1.0-1.patch
    CONFIGURE
      export CXXFLAGS=-Wno-extra-semi-stmt\ -Wno-zero-as-null-pointer-constant\ -Wno-shadow\ $ENV{CXXFLAGS} &&
      cmake
        -DCMAKE_CXX_FLAGS_RELEASE=$ENV{CXXFLAGS}
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DRAPIDJSON_BUILD_DOC=OFF
        -DCMAKE_BUILD_TYPE=Release
        <SOURCE_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
  )
endfunction()

rapidjsonMain()
