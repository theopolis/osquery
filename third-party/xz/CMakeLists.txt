# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(xzMain)
  set(name "xz")
  set(version "5.2.2")

  if(DEFINED PLATFORM_LINUX)
    set(hash "6f4bcba41125b0551f00c7f8e6a23091d0394ea801d70f086b2421ae563ba44e")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "09ef8458657814af24d60968af57800af7f2896175a235c9b2776772be9171e9")
  else()
    return()
  endif()

  set(anchor_file "lib/liblzma.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

xzMain()
