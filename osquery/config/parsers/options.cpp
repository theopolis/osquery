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
#include <osquery/flags.h>
#include <osquery/logger.h>

namespace osquery {

/**
 * @brief A simple ConfigParserPlugin for an "options" dictionary key.
 */
class OptionsConfigParserPlugin : public ConfigParserPlugin {
 public:
  std::vector<std::string> keys() const override { return {"options"}; }

  Status setUp() override;

  Status update(const std::string& source, const ParserConfig& config) override;
};

Status OptionsConfigParserPlugin::setUp() {
  data_["options"] = Json::Value();
  return Status(0, "OK");
}

Status OptionsConfigParserPlugin::update(const std::string& source,
                                         const ParserConfig& config) {
  if (config.count("options")) {
    data_ = Json::Value();
    data_["options"] = config.at("options");
  }

  for (auto it = data_["options"].begin(); it != data_["options"].end(); it++) {
    if (!it->isString()) {
      continue;
    }

    auto flag = it.name();
    if (Flag::getType(flag).empty()) {
      LOG(WARNING) << "Cannot set unknown or invalid flag: " << flag;
      return Status(1, "Unknown flag");
    }

    Flag::updateValue(flag, it->asString());
    // There is a special case for supported Gflags-reserved switches.
    if (flag == "verbose" || flag == "verbose_debug" || flag == "debug") {
      setVerboseLevel();
      if (Flag::getValue("verbose") == "true") {
        VLOG(1) << "Verbose logging enabled by config option";
      }
    }
  }

  return Status(0, "OK");
}

REGISTER_INTERNAL(OptionsConfigParserPlugin, "config_parser", "options");
}
