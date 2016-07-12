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

function platform_linux_main() {
  # GCC 5x bootstrapping.
  core_brew_tool patchelf
  core_brew_tool zlib
  core_brew_tool binutils
  core_brew_tool linux-headers

  # Build a bottle of glibc.
  local_brew_tool glibc
  $BREW postinstall glibc

  # Need LZMA for final builds.
  local_brew_tool xz

  # Additional GCC 5x bootstrapping.
  core_brew_tool gmp
  brew_tool gpatch
  core_brew_tool mpfr
  core_brew_tool libmpc
  core_brew_tool isl
  brew_tool berkeley-db

  # GCC 5x.
  core_brew_tool gcc

  # Discover and set newly installed GCC 5x.
  set_cc gcc
  set_cxx g++

  # GCC-compiled (C) dependencies.
  brew_tool pkg-config

  # Build a bottle for ncurses
  local_brew_tool ncurses

  # Need BZIP/Readline for final build.
  local_brew_tool bzip2
  brew_tool unzip
  local_brew_tool readline
  brew_tool sqlite
  core_brew_tool makedepend

  # Build a bottle for perl and openssl.
  # OpenSSL is needed for the final build.
  local_brew_tool perl --without-test
  local_brew_tool openssl

  # LLVM dependencies.
  brew_tool libxml2
  brew_tool libedit
  brew_tool libidn
  brew_tool libtool
  brew_tool m4
  brew_tool bison

  # Need libgpg-error for final build.
  local_brew_tool libgpg-error

  # More LLVM dependencies.
  brew_tool popt
  brew_tool autoconf
  brew_tool automake

  # Curl and Python are needed for LLVM mostly.
  local_brew_tool curl
  local_brew_tool python
  core_brew_tool cmake --ignore-dependencies

  # LLVM/Clang.
  local_brew_tool llvm -v --with-clang --with-clang-extra --with-compiler-rt

  # Install custom formulas, build with LLVM/clang.
  local_brew_dependency boost

  # List of LLVM-compiled dependencies.
  local_brew_dependency asio
  local_brew_dependency cpp-netlib
  local_brew_dependency google-benchmark
  local_brew_dependency pcre
  local_brew_dependency lz4
  local_brew_dependency snappy
  local_brew_dependency sleuthkit
  local_brew_dependency libmagic
  local_brew_dependency thrift
  local_brew_dependency rocksdb
  local_brew_dependency gflags
  local_brew_dependency aws-sdk-cpp
  local_brew_dependency yara
  local_brew_dependency glog
  local_brew_dependency util-linux
  local_brew_dependency libdevmapper
  local_brew_dependency libaptpkg
  local_brew_dependency libiptables
  local_brew_dependency libgcrypt
  local_brew_dependency libcryptsetup
  local_brew_dependency libudev
  local_brew_dependency libaudit
  local_brew_dependency libdpkg
}

function platform_darwin_main() {
  brew_tool xz
  # brew_tool perl --without-test # Needs -lgdbm
  brew_tool sphinx-doc
  brew_tool readline # local on Linux
  brew_tool sqlite
  core_brew_tool makedepend

  # brew_dependency zlib this is not available on Darwin
  # brew_dependency bzip2 this is also not available on Darwin
  local_brew_dependency openssl --without-test
  $BREW link --force openssl

  brew_tool pkg-config
  brew_tool cmake
  brew_tool autoconf
  brew_tool automake
  brew_tool libtool
  brew_tool m4
  brew_tool bison

  local_brew_dependency boost

  # List of LLVM-compiled dependencies.
  local_brew_dependency asio
  local_brew_dependency cpp-netlib
  local_brew_dependency google-benchmark
  local_brew_dependency pcre
  local_brew_dependency lz4
  local_brew_dependency snappy
  local_brew_dependency sleuthkit
  local_brew_dependency libmagic
  local_brew_dependency thrift
  local_brew_dependency rocksdb
  local_brew_dependency gflags
  local_brew_dependency aws-sdk-cpp
  local_brew_dependency yara
  local_brew_dependency glog
  # local_brew_dependency util-linux
  # local_brew_dependency libdevmapper
  # local_brew_dependency libaptpkg
  # local_brew_dependency libiptables
  # local_brew_dependency libgcrypt
  # local_brew_dependency libcryptsetup
  # local_brew_dependency libudev
  # local_brew_dependency libaudit
  # local_brew_dependency libdpkg
}

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

  if [[ $OS = "darwin" ]]; then
    BREW_TYPE="darwin"
  else
    BREW_TYPE="linux"
  fi

  OS_SCRIPT="$SCRIPT_DIR/provision/$OS.sh"
  if [[ -f "$OS_SCRIPT" ]]; then
    log "found $OS provision script: $OS_SCRIPT"
    source "$OS_SCRIPT"
    distro_main
  else
    log "your $OS does not use a provision script"
  fi

  # Setup the osquery dependency directory
  # One can use a non-build location using OSQUERY_DEPS=/path/to/deps
  if [[ -e "$OSQUERY_DEPS" ]]; then
    DEPS_DIR="$OSQUERY_DEPS"
  else
    DEPS_DIR="/usr/local/osquery"
  fi

  if [[ ! -d "$DEPS_DIR" ]]; then
    log "creating build dir: $DEPS_DIR"
    do_sudo mkdir -p "$DEPS_DIR"
    do_sudo chown $USER "$DEPS_DIR" > /dev/null 2>&1 || true
  fi
  cd "$DEPS_DIR"

  export PATH="$DEPS_DIR/bin:$PATH"
  setup_brew "$DEPS_DIR" "$BREW_TYPE"

  if [[ ! -z "$OSQUERY_BUILD_DEPS" ]]; then
    log "[notice]"
    log "[notice] you are choosing to build dependencies instead of installing"
    log "[notice]"
  fi

  log "running unified platform initialization"
  if [[ "$BREW_TYPE" = "darwin" ]]; then
    platform_darwin_main
  else
    platform_linux_main
  fi
  cd "$SCRIPT_DIR/../"

  # Pip may have just been installed.
  log "upgrading pip and installing python dependencies"
  PIP=`which pip`
  $PIP install --upgrade pip
  # Pip may change locations after upgrade.
  PIP=`which pip`
  $PIP install -r requirements.txt

  log "running auxiliary initialization"
  initialize $OS
}

check $1 $2
main $1 $2
