/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

// libapt-pkg uses the 'DEBUG' symbol as an enum.
#ifdef DEBUG
#undef DEBUG
#define __DEBUG
#endif

#include <apt-pkg/cachefile.h>
#include <apt-pkg/init.h>
#include <apt-pkg/metaindex.h>

#ifdef __DEBUG
#define DEBUG
#endif

#include <osquery/system.h>
#include <osquery/tables.h>

namespace osquery {
namespace tables {

/**
* @brief Empty the configuration out of memory when we're done with it
*
* Newer versions of libapt-pkg provide this as _config->Clear(), brought
* forward for compatibility with older library versions.
*/
void closeConfig() {
  const Configuration::Item* Top = _config->Tree(0);
  while (Top != 0) {
    _config->Clear(Top->FullTag());
    Top = Top->Next;
  }
}

void extractAptSourceInfo(metaIndex const* mi, QueryData& results) {
  Row r;

  r["name"] = mi->Describe();
  r["base_uri"] = mi->GetURI();
  r["release"] = mi->GetDist();
  r["type"] = mi->GetType();
  r["date"] = INTEGER(mi->GetDate());
  r["trusted"] = (mi->IsTrusted()) ? "1" : "0";
  r["signed_by"] = mi->GetSignedBy();
  r["valid_until"] = INTEGER(mi->GetValidUntil());

  results.push_back(r);
}

QueryData genAptSrcs(QueryContext& context) {
  QueryData results;

  auto dropper = DropPrivileges::get();
  dropper->dropTo("nobody");

  // Load our apt configuration into memory
  // Note: _config comes from apt-pkg/configuration.h
  //       _system comes from apt-pkg/pkgsystem.h
  pkgInitConfig(*_config);

  if (!getEnvVar("APT_CONFIG").is_initialized()) {
    _config->Set("Dir::State", "/var/lib/apt");
    _config->Set("Dir::State::status", "/var/lib/dpkg/status");
    _config->Set("Dir::Cache", "/var/cache/apt");
    _config->Set("Dir::Etc", "/etc/apt");
    _config->Set("Dir::Bin::methods", "/lib/apt/methods");
    _config->Set("Dir::Bin::solvers", "/lib/apt/solvers");
    _config->Set("Dir::Bin::planners", "/lib/apt/planners");
    _config->Set("Dir::Log", "/var/log/apt");
  }

  pkgInitSystem(*_config, _system);
  if (_system == nullptr) {
    return results;
  }

  pkgCacheFile cache_file;
  pkgSourceList* src_list = cache_file.GetSourceList();
  if (src_list != nullptr) {
    for (auto s = src_list->begin(); s != src_list->end(); s++) {
      extractAptSourceInfo(*s, results);
    }
  }

  cache_file.Close();
  closeConfig();

  return results;
}
}
}
