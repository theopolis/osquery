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
  set(version "1.27")
  set(hash "472596e480ca36d1b4721ab451b1eb40bf9b7eeff46db50ecda6e69d155b16d8")
  set(anchor_file "lib/libgpg-error.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

libgpgerrorMain()
