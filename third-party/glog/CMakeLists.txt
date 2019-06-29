# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(glogMain)
  set(name "glog")
  set(anchor_file "lib/libglog.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/glog.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_gflags)
endfunction()

glogMain()
