# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(librdkafkaMain)
  set(name "librdkafka")

  if(DEFINED PLATFORM_WINDOWS)
    return()
  endif()

  set(anchor_file "lib/librdkafka.a")

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_lib})

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_openssl)
endfunction()

librdkafkaMain()
