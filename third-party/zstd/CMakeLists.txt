# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(zstdMain)
  set(name "zstd")
  set(anchor_file "lib/libzstd.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libzstd.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  definePrebuildProject(${name}
    URL https://github.com/facebook/zstd/archive/v1.2.0.tar.gz
    SHA256 4a7e4593a3638276ca7f2a09dc4f38e674d8317bbea51626393ca73fc047cbfb
    CONFIGURE true
    BUILD
      $(MAKE) lib-release
    INSTALL
      $(MAKE) install PREFIX=<INSTALL_DIR>
    BUILD_IN_SOURCE ON
  )
endfunction()

zstdMain()
