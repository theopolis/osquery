/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <osquery/config.h>

namespace osquery {

/**
 * @brief A simple ConfigParserPlugin for an "events" dictionary key.
 */
class EventsConfigParserPlugin : public ConfigParserPlugin {
 public:
  std::vector<std::string> keys() const override { return {"events"}; }

  Status setUp() override;

  Status update(const std::string& source, const ParserConfig& config) override;
};

Status EventsConfigParserPlugin::setUp() {
  data_["events"] = Json::Value();
  return Status(0, "OK");
}

Status EventsConfigParserPlugin::update(const std::string& source,
                                        const ParserConfig& config) {
  if (config.count("events") > 0) {
    data_ = Json::Value();
    data_["events"] = config.at("events");
  }
  return Status(0, "OK");
}

REGISTER_INTERNAL(EventsConfigParserPlugin, "config_parser", "events");
}
