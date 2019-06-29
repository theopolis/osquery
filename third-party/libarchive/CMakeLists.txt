# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(archiveMain)
  set(name "libarchive")
  set(anchor_file "lib/libarchive.a")

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/archive_static.lib")
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}")
endfunction()

archiveMain()
