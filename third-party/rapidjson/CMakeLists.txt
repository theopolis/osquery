# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(rapidjsonMain)
  set(name "rapidjson")
  set(version "1.1.0")

  if(DEFINED PLATFORM_LINUX)
    set(hash "d38b3727e5acc3283cb34385cca841fca13555e3eb5139c846027a0c51b77298")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "ab8c220677cc03424d0683e36542a9dcd4eac1ff99ceae70007ce6e2462da9fa")
  elseif(DEFINED PLATFORM_WINDOWS)
    set(hash "62d59198edd5851d2c990d0e68edf7fbb633bb2816ed22adbdede03e688b0b67")
  else()
    return()
  endif()

  set(anchor_file "include/rapidjson/rapidjson.h")

  importThirdPartyHeaderOnlyLibrary("PREBUILT" "${name}" "${version}" "${hash}" "${anchor_file}" "include")
endfunction()

rapidjsonMain()
