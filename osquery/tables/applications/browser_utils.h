/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#include <osquery/filesystem.h>
#include <osquery/tables.h>

namespace osquery {
namespace tables {

QueryData genChromeBasedExtensions(QueryContext& context,
                                   const boost::filesystem::path& sub_dir);

/// A helper check to rename bool-type values as 1 or 0.
inline void jsonBoolAsInt(std::string& s) {
  if (s == "true" || s == "YES" || s == "Yes") {
    s = "1";
  } else if (s == "false" || s == "NO" || s == "No") {
    s = "0";
  }
}
}
}
