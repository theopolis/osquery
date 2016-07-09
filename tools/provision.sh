#!/usr/bin/env bash

#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.

set -e

CC=clang
CXX=clang++
CFLAGS="-fPIE -fPIC -Os -DNDEBUG -march=x86-64 -mno-avx"
CXXFLAGS="$CFLAGS"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/../build"

WORKING_DIR="/tmp/osquery-provisioning" # no longer needed
FILES_DIR="$SCRIPT_DIR/provision/files" # maybe needed
FORMULA_DIR="$SCRIPT_DIR/provision/formula"
DEPS_URL=https://osquery-packages.s3.amazonaws.com/deps # no longer needed
export PATH="$PATH:/usr/local/bin"

source "$SCRIPT_DIR/lib.sh"
source "$SCRIPT_DIR/provision/lib.sh"

function main() {
  platform OS
  distro $OS DISTRO
  threads THREADS

  if ! hash sudo 2>/dev/null; then
   echo "Please install sudo in this machine"
   exit 0
  fi

  mkdir -p "$WORKING_DIR"
  if [[ ! -z "$SUDO_USER" ]]; then
    echo "chown -h $SUDO_USER $BUILD_DIR/*"
    chown -h $SUDO_USER:$SUDO_GID "$BUILD_DIR" || true
    if [[ $OS = "linux" ]]; then
      chown -h $SUDO_USER:$SUDO_GID "$BUILD_DIR/linux" || true
    fi
  fi

  BREW_TYPE="linux"
  if [[ $OS = "oracle" ]]; then
    log "detected oracle ($DISTRO)"
    source "$SCRIPT_DIR/provision/oracle.sh"
  elif [[ $OS = "centos" ]]; then
    log "detected centos ($DISTRO)"
    source "$SCRIPT_DIR/provision/centos.sh"
  elif [[ $OS = "scientific" ]]; then
    log "detected scientific linux ($DISTRO)"
    source "$SCRIPT_DIR/provision/scientific.sh"
  elif [[ $OS = "rhel" ]]; then
    log "detected rhel ($DISTRO)"
    source "$SCRIPT_DIR/provision/rhel.sh"
  elif [[ $OS = "amazon" ]]; then
    log "detected amazon ($DISTRO)"
    source "$SCRIPT_DIR/provision/amazon.sh"
  elif [[ $OS = "ubuntu" ]]; then
    log "detected ubuntu ($DISTRO)"
    source "$SCRIPT_DIR/provision/ubuntu.sh"
  elif [[ $OS = "darwin" ]]; then
    log "detected mac os x ($DISTRO)"
    source "$SCRIPT_DIR/provision/darwin.sh"
    BREW_TYPE="darwin"
  elif [[ $OS = "freebsd" ]]; then
    log "detected freebsd ($DISTRO)"
    source "$SCRIPT_DIR/provision/freebsd.sh"
  elif [[ $OS = "fedora" ]]; then
    log "detected fedora ($DISTRO)"
    source "$SCRIPT_DIR/provision/fedora.sh"
  elif [[ $OS = "debian" ]]; then
    log "detected debian ($DISTRO)"
    source "$SCRIPT_DIR/provision/debian.sh"
  else
    fatal "could not detect the current operating system. exiting."
  fi

  # Setup the osquery dependency directory
  # One can use a non-build location using OSQUERY_DEPS=/path/to/deps
  if [[ -e "$OSQUERY_DEPS" ]]; then
    DEPS_DIR="$OSQUERY_DEPS"
  else
    DEPS_DIR="/usr/local/osquery"
  fi
  mkdir -p "$DEPS_DIR"
  chown $SUDO_USER:$SUDO_GID "$DEPS_DIR" > /dev/null 2>&1 || true
  cd "$DEPS_DIR"

  setup_brew "$DEPS_DIR" "$BREW_TYPE"
  distro_main

  cd "$SCRIPT_DIR/../"

  # Pip may have just been installed.
  log "upgrading pip and installing python dependencies"
  PIP=`which pip`
  sudo $PIP install --upgrade pip
  # Pip may change locations after upgrade.
  PIP=`which pip`
  sudo $PIP install -r requirements.txt

  initialize $OS
}

check $1 $2
main $1 $2
