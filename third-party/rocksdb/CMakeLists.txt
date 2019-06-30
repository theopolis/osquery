# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(rocksdbMain)
  set(name "rocksdb")

  set(anchor_file "lib/librocksdb_lite.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/rocksdb.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_bzip2)
  target_compile_definitions("thirdparty_${name}" INTERFACE -DROCKSDB_LITE=1)

  definePrebuildProject(${name}
    URL https://github.com/facebook/rocksdb/archive/v6.1.2.tar.gz
    SHA256 df93f3b66caa1cbe1c2862c99c33e18a5c5b24a64fb51dfe8ef805e3c9fd1cad
    CONFIGURE
      cmake
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DROCKSDB_LITE=ON
        -DWITH_GFLAGS=OFF
        -DWITH_TESTS=OFF
        -DUSE_RTTI=ON
        -DPORTABLE=ON
        -DFAIL_ON_WARNINGS=OFF
        <SOURCE_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install &&
      mv <INSTALL_DIR>/lib/librocksdb.a <INSTALL_DIR>/lib/librocksdb_lite.a
  )
endfunction()

rocksdbMain()
