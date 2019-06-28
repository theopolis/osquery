# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(poptMain)
  set(name "popt")
  set(version "1.16")

  if(DEFINED PLATFORM_LINUX)
    set(hash "36b3d4ed73ce9aef07916b91bf0f82cb019858e101cb11c1f08fef583ccbff85")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "09ef8458657814af24d60968af57800af7f2896175a235c9b2776772be9171e9")
  else()
    return()
  endif()

  set(anchor_file "lib/libpopt.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

poptMain()
