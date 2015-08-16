/*
 *  Copyright (c) 2014, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#include <boost/filesystem.hpp>

#include <osquery/filesystem.h>
#include <osquery/logger.h>

#include "osquery/events/linux/audit.h"

namespace osquery {

REGISTER(AuditEventPublisher, "event_publisher", "audit");

/**
struct audit_rule_data {
  __u32   flags;  // AUDIT_PER_{TASK,CALL}, AUDIT_PREPEND
  __u32   action; // AUDIT_NEVER, AUDIT_POSSIBLE, AUDIT_ALWAYS
  __u32   field_count;
  __u32   mask[AUDIT_BITMASK_SIZE]; // syscall(s) affected
  __u32   fields[AUDIT_MAX_FIELDS];
  __u32   values[AUDIT_MAX_FIELDS];
  __u32   fieldflags[AUDIT_MAX_FIELDS];
  __u32   buflen; // total length of string fields
  char    buf[0]; // string fields buffer
};
*/

enum AuditStatus {
  AUDIT_DISABLED = 0,
  AUDIT_ENABLED = 1,
  AUDIT_IMMUTABLE = 2,
};

/// For calls to enable the audit subsystem.
#define AUDIT_ENABLED 1

Status
AuditEventPublisher::setUp() {
  handle_ = audit_open();
  if (handle_ <= 0) {
    // Could not open the audit subsystem.
    return Status(1, "Could not open audit subsystem");
  }
  
  // The setup can try to enable auditing.
  // Todo: this should become a flag.
  audit_set_enabled(handle_, AUDIT_ENABLED);

  auto enabled = audit_is_enabled(handle_);
  if (enabled == AUDIT_IMMUTABLE || getuid() != 0) {
    // The audit subsystem is in an immutable mode.
    immutable_ = true;
  } else if (enabled != AUDIT_ENABLED) {
    // No audit subsystem is available, or an error was encountered.
    audit_close(handle_);
    return Status(1, "Audit subsystem is not enabled");
  }

  // The auditd daemon sets its PID.
  if (audit_set_pid(handle_, getpid(), WAIT_YES) < 0) {
  // Could not set our process as the userspace auditing daemon.
    return Status(1, "Could not set audit PID");
  }

  // Request only the highest priority of audit status messages.
  set_aumessage_mode(MSG_QUIET, DBG_NO);

  // Todo: remove the call to configure.
  configure();
  return Status(0, "OK");
}

void AuditEventPublisher::configure() {
  // Able to issue libaudit API calls.
  struct audit_rule_data rule;
  // Reset all members to nothing.
  memset(&rule, 0, sizeof(struct audit_rule_data));

  // Set the syscall mask for a given string-identified syscall.
  audit_rule_syscallbyname_data(&rule, "execve");

  // Apply this rule to the EXIT filter, ALWAYS.
  int rc = audit_add_rule_data(handle_, &rule, AUDIT_FILTER_EXIT, AUDIT_ALWAYS);
  if (rc < 0) {
    // Problem adding rule. If errno == EEXIST then fine.
  }

  // The audit library provides an API to send a netlink request that fills in
  // a netlink reply with audit rules. What happens if this is issued inline
  // with a query and this process is receiving audit events?
  if (audit_request_rules_list_data(handle_) <= 0) {
    // Could not request audit rules.
  }
}

void AuditEventPublisher::tearDown() {
  if (handle_ > 0) {
    audit_close(handle_);
  }
}

void handleConfigChange(const struct audit_reply& reply_) {
  // Another daemon may have taken control.
  printf("config change\n");
}

void handleStatus(const struct audit_reply& reply) {
  printf("status\n");
  //rep->status->enabled, rep->status->failure,
  //rep->status->pid, rep->status->rate_limit,
  //rep->status->backlog_limit, rep->status->lost,
  //rep->status->backlog);
}

void handleReply(const struct audit_reply& reply) {
  //printf("got reply\n");
  printf("type: %s msg: %s\n",
    audit_msg_type_to_name(reply.type),
    // Message is the for-real/already stringified message.
    (reply.message != nullptr) ? reply.message : " ");
}

void handleListRules(const struct audit_reply& reply) {
  // Store the rules response.
  printf("list rules requested\n");
}

Status AuditEventPublisher::run() {
  // Reset the reply data.
  memset(&reply_, 0, sizeof(struct audit_reply));
  int result = 0;
  while (true) {
    result = audit_get_reply(handle_, &reply_, GET_REPLY_NONBLOCKING, 0);
    if (result > 0) {
      switch (reply_.type) {
      case NLMSG_NOOP:
      case NLMSG_DONE:
      case NLMSG_ERROR:
        // Not handled, request another reply.
        break;
      case AUDIT_LIST_RULES:
        // Build rules cache.
        handleListRules(reply_);
        break;
      case AUDIT_GET:
        handleStatus(reply_);
        break;
      case (AUDIT_GET + 1)... (AUDIT_LIST_RULES - 1):
      case (AUDIT_LIST_RULES + 1)... AUDIT_LAST_USER_MSG:
        // Not interested in handling meta-commands and actions.
        break;
      case AUDIT_DAEMON_START... AUDIT_DAEMON_CONFIG: // 1200 - 1203
      case AUDIT_CONFIG_CHANGE:
        handleConfigChange(reply_);
        break;
      case AUDIT_SYSCALL: // 1300
        // A monitored syscall was issued, most likely part of a multi-record.
        handleReply(reply_);
        break;
      case AUDIT_CWD: // 1307
      case AUDIT_PATH: // 1302
      case AUDIT_EXECVE: // // 1309 (execve arguments).
      case AUDIT_EOE: // 1320 (multi-record event).
        break;
      default:
        // All other cases, pass to reply.
        handleReply(reply_);
      }
    } else if (result < 0) {
      // Fall through to the run loop cool down.
      break;
    }
  }

  // Only apply a cool down if the reply request failed.
  osquery::publisherSleep(200);
  return Status(0, "Continue");
}

bool AuditEventPublisher::shouldFire(const AuditSubscriptionContextRef& sc,
                                     const AuditEventContextRef& ec) const {
  return true;
}
}
