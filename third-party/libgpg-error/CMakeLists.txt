# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libgpgerrorMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libgpg-error")
  set(anchor_file "lib/libgpg-error.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

libgpgerrorMain()
