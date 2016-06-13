/*
*  Copyright (c) 2014-present, Facebook, Inc.
*  All rights reserved.
*
*  This source code is licensed under the BSD-style license found in the
*  LICENSE file in the root directory of this source tree. An additional grant
*  of patent rights can be found in the PATENTS file in the same directory.
*
*/

#include <string>

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>

#include <osquery/core.h>
#include <osquery/flags.h>
#include <osquery/logger.h>

#include "osquery/core/watcher.h"
#include "osquery/dispatcher/distributed.h"
#include "osquery/dispatcher/scheduler.h"

const std::string kServiceName = "osquery daemon service";
const std::string kWatcherWorkerName = "osqueryd: worker";

static SERVICE_STATUS serviceStatus = { 0 };
static SERVICE_STATUS_HANDLE serviceStatusHandle = nullptr;

#define UPDATE_STATUS(controls, state, exit_code, checkpoint)                  \
  serviceStatus.dwControlsAccepted = controls;                                 \
  serviceStatus.dwCurrentState = state;                                        \
  serviceStatus.dwWin32ExitCode = exit_code;                                   \
  serviceStatus.dwCheckPoint = checkpoint;                                     \
  if (!::SetServiceStatus(serviceStatusHandle, &serviceStatus)) {              \
    log("%s: failed to set service status (lasterror=%i)",                     \
        kServiceName.c_str(), ::GetLastError());                               \
  }

void log(const char *fmt, ...) {
  va_list vl;
  va_start(vl, fmt);

  int size = _vscprintf(fmt, vl);
  if (size) {
    char *buf = (char *)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, size + 2);
    if (buf) {
      _vsprintf_p(buf, size + 1, fmt, vl);
      OutputDebugStringA(buf);
      HeapFree(GetProcessHeap(), 0, buf);
    }
  }

  va_end(vl);
}

void WINAPI daemonControlHandler(DWORD code) {
  switch (code) {
  case SERVICE_CONTROL_STOP:

    if (serviceStatus.dwCurrentState != SERVICE_RUNNING) {
      break;
    }

    log("%s: SERVICE_CONTROL_STOP requested\n", kServiceName.c_str());

    UPDATE_STATUS(0, SERVICE_STOP_PENDING, 0, 4);

    if (osquery::Watcher::getWorker().isValid()) {
      // Bind the fate of the worker to this watcher.
      osquery::Watcher::bindFates();
    } else {
      // Otherwise the worker or non-watched process joins.
      // Stop thrift services/clients/and their thread pools.
      osquery::Dispatcher::stopServices();
    }

    break;
  default:
    break;
  }
}

void osquerydMain(int argc, char *argv[]) {
  osquery::Initializer runner(argc, argv, osquery::OSQUERY_TOOL_DAEMON);

  if (!runner.isWorker()) {
    runner.initDaemon();
  }

  // When a watchdog is used, the current daemon will fork/exec into a worker.
  // In either case the watcher may start optionally loaded extensions.
  runner.initWorkerWatcher(kWatcherWorkerName);

  // Start osquery work.
  runner.start();

  // Conditionally begin the distributed query service
  auto s = osquery::startDistributed();
  if (!s.ok()) {
    VLOG(1) << "Not starting the distributed query service: " << s.toString();
  }

  // Begin the schedule runloop.
  osquery::startScheduler();

  // Finally wait for a signal / interrupt to shutdown.
  runner.waitForShutdown();
}

void WINAPI daemonMain(DWORD argc, LPSTR *argv) {
  log("%s: daemonMain started\n", kServiceName.c_str());

  serviceStatusHandle =
      RegisterServiceCtrlHandlerA(kServiceName.c_str(), daemonControlHandler);
  if (serviceStatusHandle == nullptr) {
    // TODO: error message
    log("%s: failed to register service control handler (lastrerror=%i)", kServiceName.c_str(), ::GetLastError());
    return;
  }

  ZeroMemory(&serviceStatus, sizeof(serviceStatus));
  serviceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
  serviceStatus.dwServiceSpecificExitCode = 0;
  UPDATE_STATUS(0, SERVICE_START_PENDING, 0, 0);

  UPDATE_STATUS(SERVICE_ACCEPT_STOP, SERVICE_RUNNING, 0, 0);

  log("%s: entering osquerydMain\n", kServiceName.c_str());
  osquerydMain(argc, argv);
  log("%s: osquerydMain completed\n", kServiceName.c_str());

  UPDATE_STATUS(0, SERVICE_STOPPED, 0, 3);
}

int main(int argc, char *argv[]) {
  SERVICE_TABLE_ENTRYA serviceTable[] = {
      {(LPSTR)kServiceName.c_str(), (LPSERVICE_MAIN_FUNCTION)daemonMain},
      {nullptr, nullptr}};

  if (!::StartServiceCtrlDispatcherA(serviceTable)) {
    DWORD last_error = ::GetLastError();
    if (last_error == ERROR_FAILED_SERVICE_CONTROLLER_CONNECT) {
      // This was run as a process
      osquerydMain(argc, argv);
    } else {
      // Some other error, probably fatal
    }
  }
  return 0;
}
