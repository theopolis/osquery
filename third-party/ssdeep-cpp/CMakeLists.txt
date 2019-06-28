# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(ssdeepCppMain)
  set(name "ssdeep-cpp")
  set(version "2.14.1")

  if(DEFINED PLATFORM_LINUX)
    set(hash "9c5565c4ff9de05bd1cdb8e00ab899bdf57dad221a57a9ff57001a7814af7233")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "93f11f81eab1cc06bf11fd28bc42d7b9d02972e3705f864a9f8ef0f5ca90abcc")
  else()
    add_osquery_library(thirdparty_ssdeep-cpp INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libfuzzy.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")
endfunction()

ssdeepCppMain()
