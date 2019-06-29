# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(opensslMain)
  set(name "openssl")

  set(anchor_file "lib/libssl.a")

  set(additional_lib
    lib/libcrypto.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libeay32.lib")

    set(additional_lib
      lib/ssleay32.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_lib})
endfunction()

opensslMain()
