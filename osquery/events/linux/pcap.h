// Copyright 2004-present Facebook. All Rights Reserved.

#pragma once

#include <map>
#include <vector>

#include <pcap.h>

#include <osquery/events.h>
#include <osquery/status.h>

namespace osquery {

struct PcapSubscriptionContext : public SubscriptionContext {};

struct PcapEventContext : public EventContext {};

typedef std::shared_ptr<PcapEventContext> PcapEventContextRef;
typedef std::shared_ptr<PcapSubscriptionContext> PcapSubscriptionContextRef;

class PcapEventPublisher
    : public EventPublisher<PcapSubscriptionContext, PcapEventContext> {
  DECLARE_PUBLISHER("PcapEventPublisher");

 public:
  /// Create an `inotify` handle descriptor.
  Status setUp();
  void configure() {}
  /// Release the `inotify` handle descriptor.
  void tearDown() {}

  Status run();

  PcapEventPublisher() : EventPublisher() {}

 private:
  bool shouldFire(const PcapSubscriptionContextRef& mc,
                  const PcapEventContextRef& ec);
};
}
