# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(augeasMain)
  set(name "augeas")
  set(version "1.9.0")

  if(DEFINED PLATFORM_LINUX)
    set(hash "ddb836702845d158b7fda71d23b8f06b5368265513b6939afe8ac445f04d4b32")
  elseif(DEFINED PLATFORM_MACOS)
    set(hash "7330e0fcfbcea6f58d199916238c47078f3ea2ba85ac4ed2fa74fcb63e034b1c")
  else()
    add_osquery_library(thirdparty_augeas INTERFACE)
    return()
  endif()

  set(anchor_file "lib/libaugeas.a")

  set(additional_library
    "lib/libfa.a"
  )

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}" ${additional_library})
endfunction()

augeasMain()
