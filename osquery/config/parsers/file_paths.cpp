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
#include <osquery/filesystem.h>
#include <osquery/logger.h>

namespace osquery {

/**
 * @brief A simple ConfigParserPlugin for an "file_paths" dictionary key.
 */
class FilePathsConfigParserPlugin : public ConfigParserPlugin {
 public:
  FilePathsConfigParserPlugin();
  virtual ~FilePathsConfigParserPlugin() {}

  std::vector<std::string> keys() const override {
    return {"file_paths", "file_accesses"};
  }

  Status setUp() override { return Status(0); };

  Status update(const std::string& source, const ParserConfig& config) override;

 private:
  /// The access map binds source to category.
  std::map<std::string, std::vector<std::string> > access_map_;
};

FilePathsConfigParserPlugin::FilePathsConfigParserPlugin() {
  data_["file_paths"] = Json::Value();
  data_["file_accesses"] = Json::Value();
}

Status FilePathsConfigParserPlugin::update(const std::string& source,
                                           const ParserConfig& config) {
  if (config.count("file_paths") > 0) {
    data_["file_paths"] = config.at("file_paths");
  }

  auto& accesses = data_["file_accesses"];
  if (config.count("file_accesses") > 0) {
    if (access_map_.count(source) > 0) {
      access_map_.erase(source);
    }

    for (const auto& category : config.at("file_accesses")) {
      auto path = category.asString();
      access_map_[source].push_back(path);
    }
    // Regenerate the access:
    for (const auto& source : access_map_) {
      for (const auto& category : source.second) {
        accesses[category] = source.first;
      }
    }
  }

  Config::getInstance().removeFiles(source);
  auto& file_paths = data_["file_paths"];
  for (auto it = file_paths.begin(); it != file_paths.end(); it++) {
    for (const auto& path : *it) {
      auto pattern = path.asString();
      if (pattern.empty()) {
        continue;
      }
      replaceGlobWildcards(pattern);
      Config::getInstance().addFile(source, it.name(), pattern);
    }
  }

  return Status(0, "OK");
}

REGISTER_INTERNAL(FilePathsConfigParserPlugin, "config_parser", "file_paths");
}
