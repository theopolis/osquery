# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libiptablesMain)
  if(NOT DEFINED PLATFORM_LINUX)
    return()
  endif()

  set(name "libiptables")
  set(version "1.4.21")
  set(hash "6a80091cc47bb690581d1b1627d8ef2e4110d683f0cf598546e93ee0f5e7afab")
  set(anchor_file "lib/libip4tc.a")

  set(additional_libraries
    lib/libip6tc.a
    lib/libiptc.a
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_libraries})
endfunction()

libiptablesMain()
