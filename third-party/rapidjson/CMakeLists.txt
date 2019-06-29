# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(rapidjsonMain)
  set(name "rapidjson")
  set(anchor_file "include/rapidjson/rapidjson.h")

  importThirdPartyHeaderOnlyLibrary("PREBUILT" "${name}" "${anchor_file}" "include")
endfunction()

rapidjsonMain()
