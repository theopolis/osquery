# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(thrifMain)
  set(name "thrift")
  set(anchor_file "lib/libthrift.a")

  set(additional_library
    "lib/libthriftz.a"
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/parse.lib")

    set(additional_libraries
      lib/thriftzmt.lib
      lib/thriftmt.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_boost)
endfunction()

thrifMain()
