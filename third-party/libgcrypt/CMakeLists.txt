# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libgcryptMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libgcrypt")
  set(anchor_file "lib/libgcrypt.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_libgpg-error)
endfunction()

libgcryptMain()
