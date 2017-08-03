#include "osquery/events/linux/auditdnetlink.h"
#include "osquery/core/conversions.h"

#include <osquery/flags.h>
#include <osquery/logger.h>

#include <chrono>
#include <iostream>

#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/filesystem.hpp>
#include <boost/utility/string_ref.hpp>

#include <asm/unistd_64.h>
#include <linux/audit.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <unistd.h>

namespace {
std::string GetAuditRecordTypeName(int type) noexcept {
  // clang-format off
  const std::unordered_map<int, const char*> audit_event_name = {
    {1000, "AUDIT_GET"},
    {1001, "AUDIT_SET"},
    {1002, "AUDIT_LIST"},
    {1003, "AUDIT_ADD"},
    {1004, "AUDIT_DEL"},
    {1005, "AUDIT_USER"},
    {1006, "AUDIT_LOGIN"},
    {1007, "AUDIT_WATCH_INS"},
    {1008, "AUDIT_WATCH_REM"},
    {1009, "AUDIT_WATCH_LIST"},
    {1010, "AUDIT_SIGNAL_INFO"},
    {1011, "AUDIT_ADD_RULE"},
    {1012, "AUDIT_DEL_RULE"},
    {1013, "AUDIT_LIST_RULES"},
    {1014, "AUDIT_TRIM"},
    {1015, "AUDIT_MAKE_EQUIV"},
    {1016, "AUDIT_TTY_GET"},
    {1017, "AUDIT_TTY_SET"},
    {1018, "AUDIT_SET_FEATURE"},
    {1019, "AUDIT_GET_FEATURE"},
    {1100, "AUDIT_FIRST_USER_MSG"},
    {1107, "AUDIT_USER_AVC"},
    {1124, "AUDIT_USER_TTY"},
    {1199, "AUDIT_LAST_USER_MSG"},
    {2100, "AUDIT_FIRST_USER_MSG2"},
    {2999, "AUDIT_LAST_USER_MSG2"},
    {1200, "AUDIT_DAEMON_START"},
    {1201, "AUDIT_DAEMON_END"},
    {1202, "AUDIT_DAEMON_ABORT"},
    {1203, "AUDIT_DAEMON_CONFIG"},
    {1300, "AUDIT_SYSCALL"},
    {1301, "AUDIT_FS_WATCH"},
    {1302, "AUDIT_PATH"},
    {1303, "AUDIT_IPC"},
    {1304, "AUDIT_SOCKETCALL"},
    {1305, "AUDIT_CONFIG_CHANGE"},
    {1306, "AUDIT_SOCKADDR"},
    {1307, "AUDIT_CWD"},
    {1309, "AUDIT_EXECVE"},
    {1311, "AUDIT_IPC_SET_PERM"},
    {1312, "AUDIT_MQ_OPEN"},
    {1313, "AUDIT_MQ_SENDRECV"},
    {1314, "AUDIT_MQ_NOTIFY"},
    {1315, "AUDIT_MQ_GETSETATTR"},
    {1316, "AUDIT_KERNEL_OTHER"},
    {1317, "AUDIT_FD_PAIR"},
    {1318, "AUDIT_OBJ_PID"},
    {1319, "AUDIT_TTY"},
    {1320, "AUDIT_EOE"},
    {1321, "AUDIT_BPRM_FCAPS"},
    {1322, "AUDIT_CAPSET"},
    {1323, "AUDIT_MMAP"},
    {1324, "AUDIT_NETFILTER_PKT"},
    {1325, "AUDIT_NETFILTER_CFG"},
    {1326, "AUDIT_SECCOMP"},
    {1328, "AUDIT_FEATURE_CHANGE"},
    {1329, "AUDIT_REPLACE"},
    {1400, "AUDIT_AVC"},
    {1401, "AUDIT_SELINUX_ERR"},
    {1402, "AUDIT_AVC_PATH"},
    {1403, "AUDIT_MAC_POLICY_LOAD"},
    {1404, "AUDIT_MAC_STATUS"},
    {1405, "AUDIT_MAC_CONFIG_CHANGE"},
    {1406, "AUDIT_MAC_UNLBL_ALLOW"},
    {1407, "AUDIT_MAC_CIPSOV4_ADD"},
    {1408, "AUDIT_MAC_CIPSOV4_DEL"},
    {1409, "AUDIT_MAC_MAP_ADD"},
    {1410, "AUDIT_MAC_MAP_DEL"},
    {1411, "AUDIT_MAC_IPSEC_ADDSA"},
    {1412, "AUDIT_MAC_IPSEC_DELSA"},
    {1413, "AUDIT_MAC_IPSEC_ADDSPD"},
    {1414, "AUDIT_MAC_IPSEC_DELSPD"},
    {1415, "AUDIT_MAC_IPSEC_EVENT"},
    {1416, "AUDIT_MAC_UNLBL_STCADD"},
    {1417, "AUDIT_MAC_UNLBL_STCDEL"},
    {1700, "AUDIT_FIRST_KERN_ANOM_MSG"},
    {1799, "AUDIT_LAST_KERN_ANOM_MSG"},
    {1700, "AUDIT_ANOM_PROMISCUOUS"},
    {1701, "AUDIT_ANOM_ABEND"},
    {1702, "AUDIT_ANOM_LINK"},
    {1800, "AUDIT_INTEGRITY_DATA"},
    {1801, "AUDIT_INTEGRITY_METADATA"},
    {1802, "AUDIT_INTEGRITY_STATUS"},
    {1803, "AUDIT_INTEGRITY_HASH"},
    {1804, "AUDIT_INTEGRITY_PCR"},
    {1805, "AUDIT_INTEGRITY_RULE"},
    {2000, "AUDIT_KERNEL"}
  };
  // clang-format on

  auto it = audit_event_name.find(type);
  if (it == audit_event_name.end()) {
    std::stringstream str_helper;
    str_helper << type;
    return str_helper.str();
  }

  return it->second;
}

bool ShouldHandle(const audit_reply& reply) noexcept {
  switch (reply.type) {
  case NLMSG_NOOP:
  case NLMSG_DONE:
  case NLMSG_ERROR:
  case AUDIT_LIST_RULES:
  case AUDIT_SECCOMP:
  case AUDIT_GET:
  case (AUDIT_GET + 1)...(AUDIT_LIST_RULES - 1):
  case (AUDIT_LIST_RULES + 1)...(AUDIT_FIRST_USER_MSG - 1):
  case AUDIT_DAEMON_START ... AUDIT_DAEMON_CONFIG: // 1200 - 1203
  case AUDIT_CONFIG_CHANGE:
    return false;

  default:
    return true;
  }
}

std::ostream& operator<<(std::ostream& stream,
                         const osquery::AuditEventRecord& audit_event_record) {
  std::string audit_event_timestamp;
  auto audit_event_timestamp_it = audit_event_record.fields.find("time");
  if (audit_event_timestamp_it != audit_event_record.fields.end())
    audit_event_timestamp = audit_event_timestamp_it->second;

  stream << "audit_id=\'" << audit_event_record.audit_id << "\' ";

  if (!audit_event_timestamp.empty())
    stream << "time=\'" << audit_event_timestamp << "\' ";

  stream << "type=\'" << GetAuditRecordTypeName(audit_event_record.type)
         << "\' ";

  if (!audit_event_record.fields.empty()) {
    stream << "fields=\'";

    for (auto field_it = audit_event_record.fields.begin();
         field_it != audit_event_record.fields.end();
         field_it++) {
      stream << field_it->first << ":" << field_it->second;

      if (std::next(field_it) != audit_event_record.fields.end()) {
        stream << ", ";
      }
    }

    stream << "\'";
  }

  return stream;
}
}

namespace osquery {
/// The audit subsystem may have a performance impact on the system.
FLAG(bool,
     disable_audit,
     true,
     "Disable receiving events from the audit subsystem");

/// Control the audit subsystem by electing to be the single process sink.
FLAG(bool, audit_persist, true, "Attempt to retain control of audit");

/// Control the audit subsystem by allowing subscriptions to apply rules.
FLAG(bool,
     audit_allow_config,
     false,
     "Allow the audit publisher to change auditing configuration");

/// Audit debugger helper
HIDDEN_FLAG(bool, audit_debug, false, "Debug Linux audit messages");

// External flags
DECLARE_bool(audit_allow_process_events);
DECLARE_bool(audit_allow_sockets);
DECLARE_bool(audit_allow_fim_events);

enum AuditStatus {
  AUDIT_DISABLED = 0,
  AUDIT_ENABLED = 1,
  AUDIT_IMMUTABLE = 2,
};

AuditdNetlink& AuditdNetlink::getInstance() {
  static AuditdNetlink instance;
  return instance;
}

bool AuditdNetlink::start() noexcept {
  std::lock_guard<std::mutex> lock(initialization_mutex_);

  if (initialized_)
    return true;

  if (FLAGS_disable_audit ||
      (!FLAGS_audit_allow_process_events && !FLAGS_audit_allow_sockets &&
       !FLAGS_audit_allow_fim_events)) {
    return true;
  }

  try {
    // Allocate the read buffer before we start the threads
    const std::size_t read_buffer_size = 4096;

    read_buffer_.resize(read_buffer_size);
    if (read_buffer_.size() != read_buffer_size) {
      VLOG(1) << "Failed to allocate the audit netlink read buffer";
      return false;
    }

    // Start the reading thread
    std::packaged_task<bool(AuditdNetlink&)> recv_thread_task(
        std::bind(&AuditdNetlink::recvThread, this));

    recv_thread_.reset(
        new std::thread(std::move(recv_thread_task), std::ref(*this)));

    // Start the processing thread
    std::packaged_task<bool(AuditdNetlink&)> processing_thread_task(
        std::bind(&AuditdNetlink::processThread, this));

    processing_thread_.reset(
        new std::thread(std::move(processing_thread_task), std::ref(*this)));

    initialized_ = true;
    return true;

  } catch (const std::bad_alloc&) {
    return false;
  }
}

void AuditdNetlink::terminate() noexcept {
  std::lock_guard<std::mutex> lock(initialization_mutex_);

  terminate_threads_ = true;

  recv_thread_->join();
  processing_thread_->join();

  initialized_ = false;
}

NetlinkSubscriptionHandle AuditdNetlink::subscribe() noexcept {
  if (!start()) {
    VLOG(1) << "Failed to initialize the AuditdNetlink class";
    return 0;
  }

  std::lock_guard<std::mutex> lock(subscribers_mutex_);

  auto new_handle = ++handle_generator_;
  subscribers_[new_handle];

  subscriber_count_ = subscribers_.size();
  return new_handle;
}

void AuditdNetlink::unsubscribe(NetlinkSubscriptionHandle handle) noexcept {
  std::lock_guard<std::mutex> lock(subscribers_mutex_);

  auto it = subscribers_.find(handle);
  if (it == subscribers_.end())
    return;

  subscribers_.erase(it);
  subscriber_count_ = subscribers_.size();

  if (subscriber_count_ == 0) {
    terminate();
    initialized_ = false;
  }
}

std::vector<AuditEventRecord> AuditdNetlink::getEvents(
    NetlinkSubscriptionHandle handle) noexcept {
  if (FLAGS_disable_audit ||
      (!FLAGS_audit_allow_process_events && !FLAGS_audit_allow_sockets &&
       !FLAGS_audit_allow_fim_events)) {
    return std::vector<AuditEventRecord>();
  }

  std::vector<AuditEventRecord> audit_event_record_list;

  {
    std::lock_guard<std::mutex> subscriber_list_lock(subscribers_mutex_);

    auto subscriber_it = subscribers_.find(handle);
    if (subscriber_it == subscribers_.end())
      return std::vector<AuditEventRecord>();

    auto& context = subscriber_it->second;

    {
      std::lock_guard<std::mutex> queue_lock(context.queue_mutex);

      audit_event_record_list = std::move(context.queue);
      context.queue.clear();
    }
  }

  return audit_event_record_list;
}

bool AuditdNetlink::ParseAuditReply(const audit_reply& reply,
                                    AuditEventRecord& event_record) noexcept {
  event_record = {};

  // Tokenize the message.
  event_record.type = reply.type;
  boost::string_ref message_view(reply.message,
                                 static_cast<unsigned int>(reply.len));

  auto preamble_end = message_view.find("): ");
  if (preamble_end == std::string::npos) {
    return false;
  }

  safeStrtoul(message_view.substr(6, 10).to_string(), 10, event_record.time);
  event_record.audit_id = message_view.substr(6, preamble_end - 6).to_string();
  boost::string_ref field_view(message_view.substr(preamble_end + 3));

  // The linear search will construct series of key value pairs.
  std::string key, value;
  key.reserve(20);
  value.reserve(256);

  // There are several ways of representing value data (enclosed strings,
  // etc).
  bool found_assignment{false};
  bool found_enclose{false};

  for (const auto& c : field_view) {
    // Iterate over each character in the audit message.
    if ((found_enclose && c == '"') || (!found_enclose && c == ' ')) {
      if (c == '"') {
        value += c;
      }

      // This is a terminating sequence, the end of an enclosure or space
      // tok.
      if (!key.empty()) {
        // Multiple space tokens are supported.
        event_record.fields.emplace(
            std::make_pair(std::move(key), std::move(value)));
      }

      found_enclose = false;
      found_assignment = false;

      key.clear();
      value.clear();

    } else if (!found_assignment && c == ' ') {
      // A field tokenizer.

    } else if (found_assignment) {
      // Enclosure sequences appear immediately following assignment.
      if (c == '"') {
        found_enclose = true;
      }

      value += c;

    } else if (c == '=') {
      found_assignment = true;

    } else {
      key += c;
    }
  }

  // Last step, if there was no trailing tokenizer.
  if (!key.empty()) {
    event_record.fields.emplace(
        std::make_pair(std::move(key), std::move(value)));
  }

  return true;
}

void AuditdNetlink::AdjustAuditReply(audit_reply& reply) noexcept {
  reply.type = reply.msg.nlh.nlmsg_type;
  reply.len = reply.msg.nlh.nlmsg_len;
  reply.nlh = &reply.msg.nlh;

  reply.status = nullptr;
  reply.ruledata = nullptr;
  reply.login = nullptr;
  reply.message = nullptr;
  reply.error = nullptr;
  reply.signal_info = nullptr;
  reply.conf = nullptr;

  switch (reply.type) {
  case NLMSG_ERROR: {
    reply.error = static_cast<struct nlmsgerr*>(NLMSG_DATA(reply.nlh));
    break;
  }

  case AUDIT_LIST_RULES: {
    reply.ruledata =
        static_cast<struct audit_rule_data*>(NLMSG_DATA(reply.nlh));
    break;
  }

  case AUDIT_USER:
  case AUDIT_LOGIN:
  case AUDIT_KERNEL:
  case AUDIT_FIRST_USER_MSG ... AUDIT_LAST_USER_MSG:
  case AUDIT_FIRST_USER_MSG2 ... AUDIT_LAST_USER_MSG2:
  case AUDIT_FIRST_EVENT ... AUDIT_INTEGRITY_LAST_MSG: {
    reply.message = static_cast<char*>(NLMSG_DATA(reply.nlh));
    break;
  }

  case AUDIT_SIGNAL_INFO: {
    reply.signal_info = static_cast<audit_sig_info*>(NLMSG_DATA(reply.nlh));
    break;
  }

  default:
    break;
  }
}

bool AuditdNetlink::recvThread() noexcept {
  acquire_netlink_handle_ = true;

  int counter_to_next_status_request = 0;
  const int status_request_countdown = 1000;

  while (!terminate_threads_) {
    if (subscriber_count_ == 0) {
      std::this_thread::sleep_for(std::chrono::seconds(5));
      continue;
    }

    if (acquire_netlink_handle_) {
      if (FLAGS_audit_debug) {
        std::cout << "(re)acquiring audit handle.." << std::endl;
      }

      NetlinkStatus netlink_status = acquireHandle();

      if (netlink_status == NetlinkStatus::Disabled ||
          netlink_status == NetlinkStatus::Error) {
        std::this_thread::sleep_for(std::chrono::seconds(5));
        continue;
      }

      acquire_netlink_handle_ = false;
      counter_to_next_status_request = status_request_countdown;
    }

    if (counter_to_next_status_request == 0) {
      errno = 0;

      if (audit_request_status(audit_netlink_handle_) <= 0) {
        if (errno == ENOBUFS) {
          VLOG(1) << "Warning: Failed to request audit status (ENOBUFS). "
                     "Retrying again later...";

        } else {
          VLOG(1) << "Error: Failed to request audit status. Requesting a "
                     "handle reset";

          acquire_netlink_handle_ = true;
        }
      }

      counter_to_next_status_request = status_request_countdown;
    } else {
      --counter_to_next_status_request;
    }

    if (!acquireMessages()) {
      acquire_netlink_handle_ = true;
      continue;
    }
  }

  restoreAuditServiceConfiguration();

  audit_close(audit_netlink_handle_);
  audit_netlink_handle_ = -1;

  return true;
}

bool AuditdNetlink::processThread() noexcept {
  while (!terminate_threads_) {
    std::vector<audit_reply> queue;

    {
      std::unique_lock<std::mutex> lock(raw_audit_record_list_mutex_);

      while (raw_audit_record_list_.empty())
        raw_records_pending_.wait(lock);

      queue = std::move(raw_audit_record_list_);
      raw_audit_record_list_.clear();
    }

    std::vector<AuditEventRecord> audit_event_record_queue;

    for (auto& reply : queue) {
      AdjustAuditReply(reply);

      // This record carries the process id of the controlling daemon; in case
      // we lost control of the audit service, we are going to request a reset
      // as soon as we finish processing the pending queue
      if (reply.type == AUDIT_GET) {
        reply.status = static_cast<struct audit_status*>(NLMSG_DATA(reply.nlh));
        pid_t new_pid = static_cast<pid_t>(reply.status->pid);

        if (new_pid != getpid()) {
          VLOG(1) << "Audit control lost to pid: " << new_pid;

          if (FLAGS_audit_persist) {
            VLOG(1) << "Attempting to reacquire control of the audit service";
            acquire_netlink_handle_ = true;
          }
        }

        continue;
      }

      // We are not interested in all messages; only get the ones related to
      // syscalls and their parameters
      if (!ShouldHandle(reply))
        continue;

      // Parse the audit record body and store it into our queue
      AuditEventRecord audit_event_record = {};
      if (!ParseAuditReply(reply, audit_event_record)) {
        VLOG(1) << "Malformed audit record received";
        continue;
      }

      if (FLAGS_audit_debug) {
        std::cout << audit_event_record << std::endl;
      }

      audit_event_record_queue.push_back(audit_event_record);
    }

    // Dispatch the new records to the subscribers
    if (!audit_event_record_queue.empty()) {
      std::lock_guard<std::mutex> subscriber_list_lock(subscribers_mutex_);

      for (auto& subscriber_descriptor : subscribers_) {
        auto& subscriber_context = subscriber_descriptor.second;

        std::lock_guard<std::mutex> queue_lock(subscriber_context.queue_mutex);

        subscriber_context.queue.reserve(subscriber_context.queue.size() +
                                         audit_event_record_queue.size());

        subscriber_context.queue.insert(subscriber_context.queue.end(),
                                        audit_event_record_queue.begin(),
                                        audit_event_record_queue.end());
      }
    }

    queue.clear();
    audit_event_record_queue.clear();
  }

  return true;
}

bool AuditdNetlink::acquireMessages() noexcept {
  pollfd fds[] = {{audit_netlink_handle_, POLLIN, 0}};

  struct sockaddr_nl nladdr = {};
  socklen_t nladdrlen = sizeof(nladdr);

  bool reset_handle = false;
  std::size_t events_received = 0;

  // Attempt to read as many messages as possible before we exit
  for (events_received = 0; events_received < read_buffer_.size();
       events_received++) {
    errno = 0;
    int poll_status = ::poll(fds, 1, 1);
    if (poll_status == 0) {
      break;
    }

    else if (poll_status < 0) {
      VLOG(1) << "pool() failed with error " << errno;
      reset_handle = true;
      break;
    }

    if ((fds[0].revents & POLLIN) == 0) {
      break;
    }

    audit_reply reply;
    ssize_t len = recvfrom(audit_netlink_handle_,
                           &reply.msg,
                           sizeof(reply.msg),
                           0,
                           reinterpret_cast<struct sockaddr*>(&nladdr),
                           &nladdrlen);

    if (len < 0) {
      VLOG(1) << "Failed to receive data from the audit netlink";
      reset_handle = true;
      break;
    }

    if (nladdrlen != sizeof(nladdr)) {
      VLOG(1) << "Protocol error";
      reset_handle = true;
      break;
    }

    if (nladdr.nl_pid) {
      VLOG(1) << "Invalid netlink endpoint";
      reset_handle = true;
      break;
    }

    if (!NLMSG_OK(&reply.msg.nlh, static_cast<unsigned int>(len))) {
      if (len == sizeof(reply.msg)) {
        VLOG(1) << "Netlink event too big (EFBIG)";
      } else {
        VLOG(1) << "Broken netlink event (EBADE)";
      }

      reset_handle = true;
      break;
    }

    read_buffer_[events_received] = reply;
  }

  if (events_received != 0) {
    std::unique_lock<std::mutex> lock(raw_audit_record_list_mutex_);

    raw_audit_record_list_.reserve(raw_audit_record_list_.size() +
                                   events_received);
    raw_audit_record_list_.insert(
        raw_audit_record_list_.end(),
        read_buffer_.begin(),
        std::next(read_buffer_.begin(), events_received));

    raw_records_pending_.notify_one();
  }

  if (reset_handle) {
    VLOG(1) << "Requesting audit handle reset";
    return false;
  }

  return true;
}

bool AuditdNetlink::configureAuditService() noexcept {
  VLOG(1) << "Attempting to configure the audit service...";

  // Want to set a min sane buffer and maximum number of events/second min.
  // This is normally controlled through the audit config, but we must
  // enforce sane minimums: -b 8192 -e 100
  audit_set_backlog_wait_time(audit_netlink_handle_, 1);
  audit_set_backlog_limit(audit_netlink_handle_, 4096);
  audit_set_failure(audit_netlink_handle_, AUDIT_FAIL_SILENT);

  // Request only the highest priority of audit status messages.
  set_aumessage_mode(MSG_QUIET, DBG_NO);

  //
  // Audit rules
  //

  // Rules required by the socket_events table
  if (FLAGS_audit_allow_sockets) {
    VLOG(1) << "Enabling audit rules for the socket_events table";

    monitored_syscall_list_.insert(__NR_bind);
    monitored_syscall_list_.insert(__NR_connect);
  }

  // Rules required by the process_events table
  if (FLAGS_audit_allow_process_events) {
    VLOG(1) << "Enabling audit rules for the process_events table";
    monitored_syscall_list_.insert(__NR_execve);
  }

  // Rules required by the auditd_fim_events table
  if (FLAGS_audit_allow_fim_events) {
    VLOG(1) << "Enabling audit rules for the auditd_fim_events table";

    int syscall_list[] = {__NR_execve,
                          __NR_exit,
                          __NR_exit_group,
                          __NR_open,
                          __NR_openat,
                          __NR_name_to_handle_at,
                          __NR_open_by_handle_at,
                          __NR_close,
                          __NR_dup,
                          __NR_dup2,
                          __NR_dup3,
                          __NR_read,
                          __NR_write,
                          __NR_mmap,
                          __NR_creat,
                          __NR_mknodat,
                          __NR_mknod};

    for (int syscall : syscall_list) {
      monitored_syscall_list_.insert(syscall);
    }
  }

  // Attempt to add each one of the rules we collected
  for (int syscall_number : monitored_syscall_list_) {
    audit_rule_data rule = {};
    audit_rule_syscall_data(&rule, syscall_number);

    // clang-format off
    int rule_add_error = audit_add_rule_data(audit_netlink_handle_, &rule,
      // We want to be notified when we exit from the syscall
      AUDIT_FILTER_EXIT,

      // Always audit this syscall event
      AUDIT_ALWAYS
    );
    // clang-format on

    if (rule_add_error >= 0) {
      if (FLAGS_audit_debug) {
        std::cout << "Audit rule installed for syscall " << syscall_number
                  << std::endl;
      }

      installed_rule_list_.push_back(rule);
      continue;
    }

    if (FLAGS_audit_debug) {
      std::cout << "Audit rule for syscall " << syscall_number
                << " could not be installed. Errno: " << (-errno) << std::endl;
    }

    // If the rule we tried to apply already existed, remove it from our list
    // so that we do not revert it back when we exit
    rule_add_error = -rule_add_error;

    if (rule_add_error != EEXIST) {
      VLOG(1) << "The following syscall number could not be added to the audit "
                 "service rules: "
              << syscall_number << ". Some of the auditd "
              << "table may not work properly (process_events, "
              << "socket_events, auditd_fim_events)";
    }
  }

  return true;
}

void AuditdNetlink::restoreAuditServiceConfiguration() noexcept {
  if (FLAGS_audit_debug) {
    std::cout << "Uninstalling audit rules..." << std::endl;
  }

  // Remove the rules we have added
  VLOG(1) << "Uninstalling the audit rules we have installed";

  for (auto& rule : installed_rule_list_) {
    audit_delete_rule_data(
        audit_netlink_handle_, &rule, AUDIT_FILTER_EXIT, AUDIT_ALWAYS);
  }

  installed_rule_list_.clear();

  // Restore audit configuration defaults.
  if (FLAGS_audit_debug) {
    std::cout
        << "Audit: restoring default settings and disabling the service..."
        << std::endl;
  }

  VLOG(1) << "Restoring the default configuration for the audit service";

  audit_set_backlog_limit(audit_netlink_handle_, 0);
  audit_set_backlog_wait_time(audit_netlink_handle_, 60000);
  audit_set_failure(audit_netlink_handle_, AUDIT_FAIL_PRINTK);
  audit_set_enabled(audit_netlink_handle_, AUDIT_DISABLED);
}

NetlinkStatus AuditdNetlink::acquireHandle() noexcept {
  // Returns the audit netlink status
  auto L_GetNetlinkStatus = [](int netlink_handle) -> NetlinkStatus {
    if (netlink_handle <= 0) {
      return NetlinkStatus::Error;
    }

    if (FLAGS_disable_audit) {
      return NetlinkStatus::Disabled;
    }

    errno = 0;
    if (audit_request_status(netlink_handle) < 0 && errno != ENOBUFS) {
      return NetlinkStatus::Error;
    }

    auto enabled = audit_is_enabled(netlink_handle);

    if (enabled == AUDIT_IMMUTABLE || getuid() != 0 ||
        !FLAGS_audit_allow_config) {
      return NetlinkStatus::ActiveImmutable;

    } else if (enabled == AUDIT_ENABLED) {
      return NetlinkStatus::ActiveMutable;

    } else if (enabled == AUDIT_DISABLED) {
      return NetlinkStatus::Disabled;

    } else {
      return NetlinkStatus::Error;
    }
  };

  if (audit_netlink_handle_ != 0) {
    audit_close(audit_netlink_handle_);
    audit_netlink_handle_ = -1;
  }

  audit_netlink_handle_ = audit_open();
  if (audit_netlink_handle_ <= 0) {
    audit_netlink_handle_ = -1;
    return NetlinkStatus::Error;
  }

  if (audit_set_pid(audit_netlink_handle_, getpid(), WAIT_NO) < 0) {
    audit_close(audit_netlink_handle_);
    audit_netlink_handle_ = -1;

    return NetlinkStatus::Error;
  }

  NetlinkStatus netlink_status = L_GetNetlinkStatus(audit_netlink_handle_);
  if (FLAGS_audit_allow_config && netlink_status == NetlinkStatus::Disabled) {
    if (audit_set_enabled(audit_netlink_handle_, AUDIT_ENABLED) < 0) {
      audit_close(audit_netlink_handle_);
      audit_netlink_handle_ = -1;

      if (FLAGS_audit_debug) {
        std::cout << "Failed to enable the audit service" << std::endl;
      }

      return NetlinkStatus::Error;
    }

    if (FLAGS_audit_debug) {
      std::cout << "Audit service enabled" << std::endl;
    }
  }

  netlink_status = L_GetNetlinkStatus(audit_netlink_handle_);

  if (FLAGS_audit_allow_config &&
      netlink_status == NetlinkStatus::ActiveMutable) {
    if (!configureAuditService()) {
      audit_close(audit_netlink_handle_);
      audit_netlink_handle_ = -1;

      return NetlinkStatus::Error;
    }
  }

  return netlink_status;
}
}