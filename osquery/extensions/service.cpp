/**
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed in accordance with the terms specified in
 *  the LICENSE file found in the root directory of this source tree.
 */

#include <osquery/core/init.h>
#include <osquery/core/watcher.h>
#include <osquery/extensions/interface.h>
#include <osquery/extensions/service.h>
#include <osquery/filesystem/filesystem.h>
#include <osquery/flags.h>
#include <osquery/logger.h>
#include <osquery/registry.h>
#include <osquery/system.h>
#include <osquery/utils/config/default_paths.h>
#include <osquery/utils/conversions/join.h>
#include <osquery/utils/conversions/split.h>
#include <osquery/utils/info/platform_type.h>

#include <boost/filesystem/path.hpp>

#include <map>
#include <vector>

namespace fs = boost::filesystem;

namespace osquery {

enum class ExtendableType {
  EXTENSION = 1,
};

using ExtendableTypeSet = std::map<ExtendableType, std::set<std::string>>;

const std::map<PlatformType, ExtendableTypeSet> kFileExtensions{
    {PlatformType::TYPE_WINDOWS,
     {{ExtendableType::EXTENSION, {".exe", ".ext"}}}},
    {PlatformType::TYPE_LINUX, {{ExtendableType::EXTENSION, {".ext"}}}},
    {PlatformType::TYPE_OSX, {{ExtendableType::EXTENSION, {".ext"}}}},
};

CLI_FLAG(string,
         extensions_autoload,
         OSQUERY_HOME "extensions.load",
         "Optional path to a list of autoloaded & managed extensions");

SHELL_FLAG(string, extension, "", "Path to a single extension to autoload");

CLI_FLAG(string,
         extensions_require,
         "",
         "Comma-separated list of required extensions");

DECLARE_bool(disable_extensions);
DECLARE_string(extensions_socket);
DECLARE_string(extensions_timeout);
DECLARE_string(extensions_socket);
DECLARE_string(extensions_interval);

/// A Dispatcher service thread that watches an ExtensionManagerHandler.
class ExtensionWatcher : public InternalRunnable {
 public:
  virtual ~ExtensionWatcher() = default;
  ExtensionWatcher(const std::string& path, size_t interval, bool fatal);

 public:
  /// The Dispatcher thread entry point.
  void start() override;

  /// Perform health checks.
  virtual void watch();

 protected:
  /// Exit the extension process with a fatal if the ExtensionManager dies.
  void exitFatal(int return_code = 1);

 protected:
  /// The UNIX domain socket path for the ExtensionManager.
  std::string path_;

  /// The internal in milliseconds to ping the ExtensionManager.
  size_t interval_;

  /// If the ExtensionManager socket is closed, should the extension exit.
  bool fatal_;
};

class ExtensionManagerWatcher : public ExtensionWatcher {
 public:
  ExtensionManagerWatcher(const std::string& path, size_t interval)
      : ExtensionWatcher(path, interval, false) {}

  /// The Dispatcher thread entry point.
  void start() override;

  /// Start a specialized health check for an ExtensionManager.
  void watch() override;

 private:
  /// Allow extensions to fail for several intervals.
  std::map<RouteUUID, size_t> failures_;
};

void removeStalePaths(const std::string& manager) {
  std::vector<std::string> paths;
  // Attempt to remove all stale extension sockets.
  resolveFilePattern(manager + ".*", paths);
  for (const auto& path : paths) {
    removePath(path);
  }
}

ExtensionWatcher::ExtensionWatcher(const std::string& path,
                                   size_t interval,
                                   bool fatal)
    : InternalRunnable("ExtensionWatcher"),
      path_(path),
      interval_(interval),
      fatal_(fatal) {
  // Set the interval to a minimum of 200 milliseconds.
  interval_ = (interval_ < 200) ? 200 : interval_;
}

void ExtensionWatcher::start() {
  // Watch the manager, if the socket is removed then the extension will die.
  // A check for sane paths and activity is applied before the watcher
  // service is added and started.
  while (!interrupted()) {
    watch();
    pause(std::chrono::milliseconds(interval_));
  }
}

void ExtensionManagerWatcher::start() {
  // Watch each extension.
  while (!interrupted()) {
    watch();
    pause(std::chrono::milliseconds(interval_));
  }

  // When interrupted, request each extension tear down.
  const auto uuids = RegistryFactory::get().routeUUIDs();
  for (const auto& uuid : uuids) {
    try {
      auto path = getExtensionSocket(uuid);
      ExtensionClient client(path);
      client.shutdown();
    } catch (const std::exception& /* e */) {
      VLOG(1) << "Extension UUID " << uuid << " shutdown request failed";
      continue;
    }
  }
}

void ExtensionWatcher::exitFatal(int return_code) {
  // Exit the extension.
  // We will save the wanted return code and raise an interrupt.
  // This interrupt will be handled by the main thread then join the watchers.
  Initializer::requestShutdown(return_code);
}

void ExtensionWatcher::watch() {
  // Attempt to ping the extension core.
  // This does NOT use pingExtension to avoid the latency checks applied.
  Status status;
  bool core_sane = true;
  if (socketExists(path_)) {
    try {
      ExtensionManagerClient client(path_);
      // Ping the extension manager until it goes down.
      status = client.ping();
    } catch (const std::exception& /* e */) {
      core_sane = false;
    }
  } else {
    // The previously-writable extension socket is not usable.
    core_sane = false;
  }

  if (!core_sane) {
    VLOG(1) << "Extension watcher ending: osquery core has gone away";
    exitFatal(0);
  }

  if (status.getCode() != (int)ExtensionCode::EXT_SUCCESS && fatal_) {
    // The core may be healthy but return a failed ping status.
    exitFatal();
  }
}

void ExtensionManagerWatcher::watch() {
  // Watch the set of extensions, if the socket is removed then the extension
  // will be deregistered.
  const auto uuids = RegistryFactory::get().routeUUIDs();

  Status status;
  for (const auto& uuid : uuids) {
    auto path = getExtensionSocket(uuid);
    auto exists = socketExists(path);

    if (!exists.ok() && failures_[uuid] == 0) {
      // If there was never a failure then this is the first attempt.
      // Allow the extension to be latent and respect the autoload timeout.
      VLOG(1) << "Extension UUID " << uuid << " initial check failed";
      exists = extensionPathActive(path, true);
    }

    // All extensions will have a single failure (and odd use of the counting).
    // If failures get to 2 then the extension will be removed.
    failures_[uuid] = 1;
    if (exists.ok()) {
      try {
        ExtensionClient client(path);
        // Ping the extension until it goes down.
        status = client.ping();
      } catch (const std::exception& /* e */) {
        failures_[uuid] += 1;
        continue;
      }
    } else {
      // Immediate fail non-writable paths.
      failures_[uuid] += 1;
      continue;
    }

    if (status.getCode() != (int)ExtensionCode::EXT_SUCCESS) {
      LOG(INFO) << "Extension UUID " << uuid << " ping failed";
      failures_[uuid] += 1;
    } else {
      failures_[uuid] = 1;
    }
  }

  for (const auto& uuid : failures_) {
    if (uuid.second > 1) {
      LOG(INFO) << "Extension UUID " << uuid.first << " has gone away";
      RegistryFactory::get().removeBroadcast(uuid.first);
      failures_[uuid.first] = 1;
    }
  }
}

ExtensionRunnerCore::~ExtensionRunnerCore() = default;

ExtensionRunnerCore::ExtensionRunnerCore(const std::string& path)
    : InternalRunnable("ExtensionRunnerCore"), ExtensionRunnerInterface() {
  path_ = path;
}

void ExtensionRunnerCore::stop() {
  {
    WriteLock lock(service_start_);
    service_stopping_ = true;
  }

  stopServer();
}

void ExtensionRunnerCore::startServer() {
  {
    WriteLock lock(service_start_);
    // A request to stop the service may occur before the thread starts.
    if (service_stopping_) {
      return;
    }

    if (!isPlatform(PlatformType::TYPE_WINDOWS)) {
      // Before starting and after stopping the manager, remove stale sockets.
      // This is not relevant in Windows
      removeStalePaths(path_);
    }

    connect();
  }

  serve();
}

ExtensionRunner::ExtensionRunner(const std::string& manager_path,
                                 RouteUUID uuid)
    : ExtensionRunnerCore(""), uuid_(uuid) {
  path_ = getExtensionSocket(uuid, manager_path);
}

RouteUUID ExtensionRunner::getUUID() const {
  return uuid_;
}

void ExtensionRunner::start() {
  setThreadName(name() + " " + path_);
  init(uuid_);

  VLOG(1) << "Extension service starting: " << path_;
  try {
    startServer();
  } catch (const std::exception& e) {
    LOG(ERROR) << "Cannot start extension handler: " << path_ << " ("
               << e.what() << ")";
  }
}

ExtensionManagerRunner::ExtensionManagerRunner(const std::string& manager_path)
    : ExtensionRunnerCore(manager_path) {}

ExtensionManagerRunner::~ExtensionManagerRunner() {
  // Only attempt to remove stale paths if the server was started.
  WriteLock lock(service_start_);
  stopServerManager();
}

void ExtensionManagerRunner::start() {
  init(0, true);

  VLOG(1) << "Extension manager service starting: " << path_;
  try {
    startServer();
  } catch (const std::exception& e) {
    LOG(WARNING) << "Extensions disabled: cannot start extension manager ("
                 << path_ << ") (" << e.what() << ")";
  }
}

void initShellSocket(const std::string& homedir) {
  if (!Flag::isDefault("extensions_socket")) {
    return;
  }

  if (isPlatform(PlatformType::TYPE_WINDOWS)) {
    osquery::FLAGS_extensions_socket = "\\\\.\\pipe\\shell.em";
  } else {
    osquery::FLAGS_extensions_socket =
        (fs::path(homedir) / "shell.em").make_preferred().string();
  }

  if (extensionPathActive(FLAGS_extensions_socket, false) ||
      !socketExists(FLAGS_extensions_socket, true)) {
    // If there is an existing shell using this socket, or the socket cannot
    // be used (another user using the same path?)
    FLAGS_extensions_socket += std::to_string((uint16_t)rand());
  }
}

void loadExtensions() {
  // Disabling extensions will disable autoloading.
  if (FLAGS_disable_extensions) {
    return;
  }

  // Optionally autoload extensions, sanitize the binary path and inform
  // the osquery watcher to execute the extension when started.
  auto status = loadExtensions(
      fs::path(FLAGS_extensions_autoload).make_preferred().string());
  if (!status.ok()) {
    VLOG(1) << "Could not autoload extensions: " << status.what();
  }
}

static bool isFileSafe(std::string& path, ExtendableType type) {
  boost::trim(path);
  // A 'type name' may be used in verbose log output.
  std::string type_name =
      ((type == ExtendableType::EXTENSION) ? "extension" : "module");
  if (path.size() == 0 || path[0] == '#' || path[0] == ';') {
    return false;
  }

  // Resolve acceptable extension binaries from autoload paths.
  if (isDirectory(path).ok()) {
    VLOG(1) << "Cannot autoload " << type_name << " from directory: " << path;
    return false;
  }

  std::set<std::string> exts;
  if (isPlatform(PlatformType::TYPE_LINUX)) {
    exts = kFileExtensions.at(PlatformType::TYPE_LINUX).at(type);
  } else if (isPlatform(PlatformType::TYPE_OSX)) {
    exts = kFileExtensions.at(PlatformType::TYPE_OSX).at(type);
  } else {
    exts = kFileExtensions.at(PlatformType::TYPE_WINDOWS).at(type);
  }

  // Only autoload file which were safe at the time of discovery.
  // If the binary later becomes unsafe (permissions change) then it will fail
  // to reload if a reload is ever needed.
  fs::path extendable(path);
  // Set the output sanitized path.
  path = extendable.string();
  if (!pathExists(path).ok()) {
    LOG(WARNING) << type_name << " doesn't exist at: " << path;
    return false;
  }
  if (!safePermissions(extendable.parent_path().string(), path, true)) {
    LOG(WARNING) << "Will not autoload " << type_name
                 << " with unsafe directory permissions: " << path;
    return false;
  }

  if (exts.find(extendable.extension().string()) == exts.end()) {
    std::string ends = osquery::join(exts, "', '");
    LOG(WARNING) << "Will not autoload " << type_name
                 << " not ending in one of '" << ends << "': " << path;
    return false;
  }

  VLOG(1) << "Found autoloadable " << type_name << ": " << path;
  return true;
}

Status loadExtensions(const std::string& loadfile) {
  if (!FLAGS_extension.empty()) {
    // This is a shell-only development flag for quickly loading/using a single
    // extension. It bypasses the safety check.
    Watcher::get().addExtensionPath(FLAGS_extension);
  }

  std::string autoload_paths;
  if (!readFile(loadfile, autoload_paths).ok()) {
    return Status(1, "Failed reading: " + loadfile);
  }

  // The set of binaries to auto-load, after safety is confirmed.
  std::set<std::string> autoload_binaries;
  for (auto& path : osquery::split(autoload_paths, "\n")) {
    if (isDirectory(path)) {
      std::vector<std::string> paths;
      listFilesInDirectory(path, paths, true);
      for (auto& embedded_path : paths) {
        if (isFileSafe(embedded_path, ExtendableType::EXTENSION)) {
          autoload_binaries.insert(std::move(embedded_path));
        }
      }
    } else if (isFileSafe(path, ExtendableType::EXTENSION)) {
      autoload_binaries.insert(path);
    }
  }

  for (const auto& binary : autoload_binaries) {
    // After the path is sanitized the watcher becomes responsible for
    // forking and executing the extension binary.
    Watcher::get().addExtensionPath(binary);
  }
  return Status::success();
}

Status startExtension(const std::string& name, const std::string& version) {
  return startExtension(name, version, "0.0.0");
}

Status startExtension(const std::string& name,
                      const std::string& version,
                      const std::string& min_sdk_version) {
  // Tell the registry that this is an extension.
  // When a broadcast is requested this registry should not send core plugins.
  RegistryFactory::get().setExternal();

  // Latency converted to milliseconds, used as a thread interruptible.
  auto latency = atoi(FLAGS_extensions_interval.c_str()) * 1000;
  auto status = startExtensionWatcher(FLAGS_extensions_socket, latency, true);
  if (!status.ok()) {
    // If the threaded watcher fails to start, fail the extension.
    return status;
  }

  status = startExtension(
      FLAGS_extensions_socket, name, version, min_sdk_version, kSDKVersion);
  if (!status.ok()) {
    // If the extension failed to start then the EM is most likely unavailable.
    return status;
  }
  return Status(0);
}

Status startExtension(const std::string& manager_path,
                      const std::string& name,
                      const std::string& version,
                      const std::string& min_sdk_version,
                      const std::string& sdk_version) {
  // Make sure the extension manager path exists, and is writable.
  auto status = extensionPathActive(manager_path, true);
  if (!status.ok()) {
    return status;
  }

  // The Registry broadcast is used as the ExtensionRegistry.
  auto broadcast = RegistryFactory::get().getBroadcast();
  // The extension will register and provide name, version, sdk details.
  ExtensionInfo info;
  info.name = name;
  info.version = version;
  info.sdk_version = sdk_version;
  info.min_sdk_version = min_sdk_version;

  // If registration is successful, we will also request the manager's options.
  OptionList options;
  // Register the extension's registry broadcast with the manager.
  RouteUUID uuid = 0;
  try {
    ExtensionManagerClient client(manager_path);
    status = client.registerExtension(info, broadcast, uuid);
    // The main reason for a failed registry is a duplicate extension name
    // (the extension process is already running), or the extension broadcasts
    // a duplicate registry item.
    if (status.getCode() == (int)ExtensionCode::EXT_FAILED) {
      return status;
    }
    // Request the core options, mainly to set the active registry plugins for
    // logger and config.
    options = client.options();
  } catch (const std::exception& e) {
    return Status(1, "Extension register failed: " + std::string(e.what()));
  }

  // Now that the UUID is known, try to clean up stale socket paths.
  auto extension_path = getExtensionSocket(uuid, manager_path);

  status = socketExists(extension_path, true);
  if (!status) {
    return status;
  }

  // Set the active config and logger plugins. The core will arbitrate if the
  // plugins are not available in the extension's local registry.
  auto& rf = RegistryFactory::get();
  rf.setActive("config", options["config_plugin"].value);
  rf.setActive("logger", options["logger_plugin"].value);
  rf.setActive("distributed", options["distributed_plugin"].value);
  // Set up all lazy registry plugins and the active config/logger plugin.
  rf.setUp();

  // Start the extension's Thrift server
  Dispatcher::addService(std::make_shared<ExtensionRunner>(manager_path, uuid));
  VLOG(1) << "Extension (" << name << ", " << uuid << ", " << version << ", "
          << sdk_version << ") registered";
  return Status(0, std::to_string(uuid));
}

Status startExtensionWatcher(const std::string& manager_path,
                             size_t interval,
                             bool fatal) {
  // Make sure the extension manager path exists, and is writable.
  auto status = extensionPathActive(manager_path, true);
  if (!status.ok()) {
    return status;
  }

  // Start a extension watcher, if the manager dies, so should we.
  Dispatcher::addService(
      std::make_shared<ExtensionWatcher>(manager_path, interval, fatal));
  return Status::success();
}

Status startExtensionManager() {
  if (FLAGS_disable_extensions) {
    return Status(1, "Extensions disabled");
  }
  return startExtensionManager(FLAGS_extensions_socket);
}

Status startExtensionManager(const std::string& manager_path) {
  // Check if the socket location is ready for a new Thrift server.
  // We expect the path to be invalid or a removal attempt to succeed.
  auto status = socketExists(manager_path, true);
  if (!status.ok()) {
    return status;
  }

  // Seconds converted to milliseconds, used as a thread interruptible.
  auto latency = atoi(FLAGS_extensions_interval.c_str()) * 1000;
  // Start a extension manager watcher, to monitor all registered extensions.
  status = Dispatcher::addService(
      std::make_shared<ExtensionManagerWatcher>(manager_path, latency));

  if (!status.ok()) {
    return status;
  }

  // Start the extension manager thread.
  status = Dispatcher::addService(
      std::make_shared<ExtensionManagerRunner>(manager_path));

  if (!status.ok()) {
    return status;
  }

  // The shell or daemon flag configuration may require an extension.
  if (!FLAGS_extensions_require.empty()) {
    bool waited = false;
    auto extensions = osquery::split(FLAGS_extensions_require, ",");
    for (const auto& extension : extensions) {
      status = applyExtensionDelay(([extension, &waited](bool& stop) {
        ExtensionList registered_extensions;
        if (getExtensions(registered_extensions).ok()) {
          for (const auto& existing : registered_extensions) {
            if (existing.second.name == extension) {
              return pingExtension(getExtensionSocket(existing.first));
            }
          }
        }

        if (waited) {
          // If we have already waited for the timeout period, stop early.
          stop = true;
        }
        return Status(
            1, "Required extension not found or not loaded: " + extension);
      }));

      // A required extension was not loaded.
      waited = true;
      if (!status.ok()) {
        LOG(WARNING) << status.getMessage();
        return status;
      }
    }
  }

  return Status::success();
}
} // namespace osquery
