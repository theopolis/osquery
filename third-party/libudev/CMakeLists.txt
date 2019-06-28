# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(libudevMain)
  set(name "libudev")
  set(version "173")
  set(hash "0be44e9788121bf192219b8b9a5713f54b545e1b4faabd4e261a25f25cdcc447")
  set(anchor_file "lib/libudev.a")

  importThirdPartyBinaryLibrary("${name}" "${version}" "${hash}" "${anchor_file}")

endfunction()

libudevMain()
