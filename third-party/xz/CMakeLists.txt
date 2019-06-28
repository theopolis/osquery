# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(xzMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "xz")
  set(version "5.2.2")
  set(hash "6f4bcba41125b0551f00c7f8e6a23091d0394ea801d70f086b2421ae563ba44e")
  set(anchor_file "lib/liblzma.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

xzMain()
