/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <sstream>
#include <vector>

#include <json/reader.h>

#include <osquery/distributed.h>
#include <osquery/enroll.h>
#include <osquery/flags.h>
#include <osquery/registry.h>

#include "osquery/remote/requests.h"
#include "osquery/remote/serializers/json.h"
#include "osquery/remote/transports/tls.h"
#include "osquery/remote/utility.h"

namespace osquery {

FLAG(string,
     distributed_tls_read_endpoint,
     "",
     "TLS/HTTPS endpoint for distributed query retrieval");

FLAG(string,
     distributed_tls_write_endpoint,
     "",
     "TLS/HTTPS endpoint for distributed query results");

FLAG(uint64,
     distributed_tls_max_attempts,
     3,
     "Number of times to attempt a request")

class TLSDistributedPlugin : public DistributedPlugin {
 public:
  Status setUp();
  Status getQueries(std::string& json);
  Status writeResults(const std::string& json);

 protected:
  std::string read_uri_;
  std::string write_uri_;
};

REGISTER(TLSDistributedPlugin, "distributed", "tls");

Status TLSDistributedPlugin::setUp() {
  read_uri_ = TLSRequestHelper::makeURI(FLAGS_distributed_tls_read_endpoint);
  write_uri_ = TLSRequestHelper::makeURI(FLAGS_distributed_tls_write_endpoint);
  return Status(0, "OK");
}

Status TLSDistributedPlugin::getQueries(std::string& json) {
  return TLSRequestHelper::go<JSONSerializer>(
      read_uri_, json, FLAGS_distributed_tls_max_attempts);
}

Status TLSDistributedPlugin::writeResults(const std::string& json) {
  Json::Value params;
  Json::Reader reader;

  if (!reader.parse(json, params, false)) {
    return Status(1, "Could not parse JSON");
  }

  std::string response;
  return TLSRequestHelper::go<JSONSerializer>(
      write_uri_, params, response, FLAGS_distributed_tls_max_attempts);
}
}
