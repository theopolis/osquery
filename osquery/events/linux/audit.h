/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#pragma once

#include <map>
#include <vector>

#include <libaudit.h>

#include <osquery/events.h>

namespace osquery {

struct AuditSubscriptionContext : public SubscriptionContext {
 private:
  friend class AuditEventPublisher;
};

struct AuditEventContext : public EventContext {};

typedef std::shared_ptr<AuditEventContext> AuditEventContextRef;
typedef std::shared_ptr<AuditSubscriptionContext> AuditSubscriptionContextRef;

class AuditEventPublisher
    : public EventPublisher<AuditSubscriptionContext, AuditEventContext> {
  DECLARE_PUBLISHER("audit");

 public:
  Status setUp();
  void configure();
  void tearDown();

  Status run();

  AuditEventPublisher() : EventPublisher() {}

 private:
  bool shouldFire(const AuditSubscriptionContextRef& mc,
                  const AuditEventContextRef& ec) const;

 private:
  /// Audit subsystem (netlink) socket descriptor.
  int handle_{0};

  /// Audit subsystem is in an immutable state.
  bool immutable_{false};

  struct audit_reply reply_;
};
}
