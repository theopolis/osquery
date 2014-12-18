// Copyright 2004-present Facebook. All Rights Reserved.

#include <sstream>

#include <glog/logging.h>

#include <osquery/events.h>
#include <osquery/filesystem.h>

#include "osquery/events/linux/pcap.h"

namespace osquery {

REGISTER_EVENTPUBLISHER(PcapEventPublisher);

Status PcapEventPublisher::setUp() {
  return Status(0, "OK");
}

Status PcapEventPublisher::run() {
  return (1, "NOPE");
}

}
