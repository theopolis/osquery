/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <osquery/distributed.h>
#include <osquery/flags.h>

#include "osquery/dispatcher/distributed.h"

namespace osquery {

FLAG(uint64,
     distributed_interval,
     60,
     "Seconds between polling for new queries (default 60)")

DECLARE_bool(disable_distributed);
DECLARE_string(distributed_plugin);

void DistributedRunner::start() {
#ifndef WIN32
  auto dist = Distributed();
  while (!interrupted()) {
    dist.pullUpdates();
    if (dist.getPendingQueryCount() > 0) {
      dist.runQueries();
    }
    pauseMilli(FLAGS_distributed_interval * 1000);
  }
#endif
}

Status startDistributed() {
#ifndef WIN32
  if (!FLAGS_disable_distributed && !FLAGS_distributed_plugin.empty() &&
      Registry::getActive("distributed") == FLAGS_distributed_plugin) {
    Dispatcher::addService(std::make_shared<DistributedRunner>());
    return Status(0, "OK");
  } else {
    return Status(1, "Distributed query service not enabled.");
  }
#else
  return Status(0, "OK");
#endif
}
}
