# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libauditMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libaudit")
  set(anchor_file "lib/libaudit.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

endfunction()

libauditMain()
