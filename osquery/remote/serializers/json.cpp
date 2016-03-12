/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <json/reader.h>
#include <json/writer.h>

#include "osquery/remote/serializers/json.h"

namespace osquery {

Status JSONSerializer::serialize(const Json::Value& params,
                                 std::string& serialized) {
  Json::FastWriter writer;
  serialized = writer.write(params);
  return Status(0, "OK");
}

Status JSONSerializer::deserialize(const std::string& serialized,
                                   Json::Value& params) {
  Json::Reader reader;
  if (!reader.parse(serialized, params, false)) {
    return Status(1, "Could not parse JSON");
  }
  return Status(0, "OK");
}
}
