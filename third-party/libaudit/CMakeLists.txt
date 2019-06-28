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
  set(version "2.4.2")
  set(hash "e457273959f2da3be6c6252860949d76f7e133651f5d7e57a69eea76387d0fc6")
  set(anchor_file "lib/libaudit.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")

endfunction()

libauditMain()
