/**
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed in accordance with the terms specified in
 *  the LICENSE file found in the root directory of this source tree.
 */

#include <boost/algorithm/string.hpp>

#include <osquery/core/system.h>
#include <osquery/core/tables.h>
#include <osquery/logger/logger.h>
#include <osquery/sql/sql.h>

#include <osquery/core/windows/wmi.h>
#include <osquery/utils/conversions/tryto.h>
#include <osquery/utils/conversions/windows/strings.h>

namespace osquery {
namespace tables {

QueryData genVideoInfo(QueryContext& context) {
  Row r;
  QueryData results;

  const WmiRequest wmiSystemReq("SELECT * FROM Win32_VideoController");
  const std::vector<WmiResultItem>& wmiResults = wmiSystemReq.results();
  if (wmiResults.empty()) {
    LOG(WARNING) << "Failed to retrieve video information";
    return {};
  } else {
    long bitsPerPixel = 0;
    wmiResults[0].GetLong("CurrentBitsPerPixel", bitsPerPixel);
    r["color_depth"] = INTEGER(bitsPerPixel);
    wmiResults[0].GetString("InstalledDisplayDrivers", r["driver"]);
    std::string cimDriverDate{""};
    wmiResults[0].GetString("DriverDate", cimDriverDate);
    r["driver_date"] = BIGINT(cimDatetimeToUnixtime(cimDriverDate));
    wmiResults[0].GetString("DriverVersion", r["driver_version"]);
    wmiResults[0].GetString("AdapterCompatibility", r["manufacturer"]);
    wmiResults[0].GetString("VideoProcessor", r["model"]);
    wmiResults[0].GetString("Name", r["series"]);
    wmiResults[0].GetString("VideoModeDescription", r["video_mode"]);
  }

  results.push_back(r);
  return results;
}
} // namespace tables
} // namespace osquery
