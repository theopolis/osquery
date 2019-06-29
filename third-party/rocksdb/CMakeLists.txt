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
endfunction()

rocksdbMain()
