# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(augeasMain)
  set(name "augeas")

  if(DEFINED PLATFORM_WINDOWS)
    add_osquery_library(thirdparty_augeas INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libaugeas.a")

  set(additional_library
    "lib/libfa.a"
  )

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_library})
endfunction()

augeasMain()
