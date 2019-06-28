# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(sleuthkitMain)
  set(name "sleuthkit")
  set(version "4.6.1")

  if(DEFINED PLATFORM_LINUX)
    set(hash "f3c93a2b1faa50cecf7082200b473804b7565ed3edabff39cff8b981daaad3b7")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "a841486e4972f262baf195d1e5ec91e9800d6f3934689407b270efc8ba465e51")
  else()
    return()
  endif()

  set(anchor_file "lib/libtsk.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

sleuthkitMain()
