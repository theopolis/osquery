/*
 *  Copyright (c) 2015, Wesley Shields
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <boost/filesystem.hpp>

#include <osquery/logger.h>
#include <osquery/tables.h>
#include <osquery/status.h>

#include "osquery/tables/utils/yara_utils.h"

#ifdef CONCAT
#undef CONCAT
#endif
#include <yara.h>

namespace osquery {
namespace tables {

Row generateRow(std::string path) {
  Row r;

  // These are filled in depending upon what is used to scan.
  r["sigfile"] = std::string("");
  r["sig_group"] = std::string("");

  // These are default values, to be updated in YARACallback.
  r["count"] = INTEGER(0);
  r["matches"] = std::string("");

  // XXX: use target_path instead to be consistent with yara_events?
  r["path"] = path;

  return r;
}

QueryData genYara(QueryContext& context) {
  QueryData results;

  auto paths = context.constraints["path"].getAll(EQUALS);
  auto groups = context.constraints["sig_group"].getAll(EQUALS);
  auto sigfiles = context.constraints["sigfile"].getAll(EQUALS);

  // Must specify a path constraint and at least one of sig_group or sigfile.
  if (paths.size() == 0 || (groups.size() == 0 && sigfiles.size() == 0)) {
    return results;
  }

  // XXX: Abstract this into a common "get rules for group" function.
  ConfigDataInstance config;
  const auto& parser = config.getParser("yara");
  if (parser == nullptr) {
    return results;
  }
  const auto& yaraParser = std::static_pointer_cast<YARAConfigParserPlugin>(parser);
  auto rules = yaraParser->rules();

  for (const auto& path_string : paths) {
    boost::filesystem::path path = path_string;
    if (!boost::filesystem::is_regular_file(path)) {
      continue;
    }

    for (const auto& group : groups) {
      if (rules.count(group) == 0)
        continue;

      Row r = generateRow(path_string);
      r["sig_group"] = std::string(group);

      VLOG(1) << "Scanning with group: " << group;
      int result = yr_rules_scan_file(rules[group],
                                      path_string.c_str(),
                                      SCAN_FLAGS_FAST_MODE,
                                      YARACallback,
                                      (void*)&r,
                                      0);

      if (result != ERROR_SUCCESS) {
        return results;
      }
      results.push_back(r);
    }

    for (const auto& file : sigfiles) {
      YR_RULES* rules = nullptr;

      std::string full_path;
      if (file[0] != '/') {
        full_path = std::string("/var/osquery/") + file;
      } else {
        full_path = file;
      }

      VLOG(1) << "Scanning with file: " << full_path;
      Status status = compileSingleFile(full_path, &rules);
      if (status.ok()) {
        Row r = generateRow(path_string);
        r["sigfile"] = std::string(file);

        int result = yr_rules_scan_file(rules,
                                        path_string.c_str(),
                                        SCAN_FLAGS_FAST_MODE,
                                        YARACallback,
                                        (void*)&r,
                                        0);

        if (result != ERROR_SUCCESS) {
          return results;
        }
        yr_rules_destroy(rules);
        results.push_back(r);
      } else {
        VLOG(1) << status.toString();
      }
    }
  }

  return results;
}
}
}
