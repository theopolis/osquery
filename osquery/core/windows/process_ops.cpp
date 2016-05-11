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
#include <vector>

#include <boost/optional.hpp>

#include "osquery/core/process.h"

namespace osquery {

bool isLauncherProcessDead(PlatformProcess &launcher) {
  DWORD code = 0;
  if (!::GetExitCodeProcess(launcher.nativeHandle(), &code)) {
    // TODO(#1991): If an error occurs with GetExitCodeProcess, do we want to
    // return a Status object to describe the error with more granularity?
    return false;
  }

  return (code != STILL_ACTIVE);
}

bool setEnvVar(const std::string &name, const std::string &value) {
  return (::SetEnvironmentVariableA(name.c_str(), value.c_str()) == TRUE);
}

bool unsetEnvVar(const std::string &name) {
  return (::SetEnvironmentVariableA(name.c_str(), NULL) == TRUE);
}

boost::optional<std::string> getEnvVar(const std::string &name) {
  const int kInitialBufferSize = 1024;
  std::vector<char> buf;
  buf.assign(kInitialBufferSize, '\0');

  DWORD value_len =
      ::GetEnvironmentVariableA(name.c_str(), &buf[0], kInitialBufferSize);
  if (value_len == 0) {
    // TODO(#1991): Do we want figure out a way to be more granular in terms of
    // the error to return?
    return boost::none;
  }

  // It is always possible that between the first GetEnvironmentVariableA call
  // and this one, a change was made to our target environment variable that
  // altered the size. Currently, we ignore this scenario and fail if the
  // returned size is greater than what we expect.
  if (value_len > kInitialBufferSize) {
    buf.assign(value_len, '\0');
    value_len = ::GetEnvironmentVariableA(name.c_str(), &buf[0], value_len);
    if (value_len == 0 || value_len > buf.size()) {
      // The size returned is greater than the size we expected. Currently, we
      // will not deal with this scenario and just return as if an error has
      // occurred.
      return boost::none;
    }
  }

  return std::string(&buf[0], value_len);
}

void cleanupDefunctProcesses() {}

ProcessState checkChildProcessStatus(const PlatformProcess &process,
                                     int &status) {
  DWORD exit_code = 0;
  if (!::GetExitCodeProcess(process.nativeHandle(), &exit_code)) {
    return PROCESS_ERROR;
  }

  if (exit_code == STILL_ACTIVE) {
    return PROCESS_STILL_ALIVE;
  }

  status = exit_code;
  return PROCESS_EXITED;
}

void setToBackgroundPriority() {}
}
