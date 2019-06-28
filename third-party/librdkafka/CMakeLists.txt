# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(librdkafkaMain)
  set(name "librdkafka")
  set(version "0.11.3")

  if(DEFINED PLATFORM_LINUX)
    set(hash "a4c18be8a3e5a7ee9afa2061af254498c6f20ec54ec3f6571b5e09683fb41a64")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "61790b76923d0005734db6209d99cd2c262cf2227500261244c208918e8b79b7")
  else()
    return()
  endif()

  set(anchor_file "lib/librdkafka.a")

  set(additional_lib
    lib/librdkafka++.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_lib})
endfunction()

librdkafkaMain()
