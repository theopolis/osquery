#!/usr/bin/env bash

#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.

function distro_main() {
  package git
  package gawk
  package ruby
  package gcc

  # GCC 5x bootstrapping.
  brew_tool patchelf
  brew_tool zlib
  brew_tool binutils
  brew_tool linux-headers
  brew_tool glibc
  brew_tool xz
  brew_tool gmp
  brew_tool gpatch
  brew_tool mpfr
  brew_tool libmpc
  brew_tool isl

  # GCC 5x.
  brew_tool gcc

  set_cc gcc
  set_cxx g++

  # GCC-compiled (C) dependencies.
  brew_tool ncurses
  brew_tool unzip
  brew_tool bzip2
  brew_tool readline
  brew_tool sqlite
  brew_tool openssl
  brew_tool libxml2
  brew_tool libedit
  brew_tool libidn

  # LLVM dependencies.
  brew_tool pkg-config
  brew_tool curl
  brew_tool gdbm
  brew_tool perl --without-test
  brew_tool python
  brew_tool cmake

  # LLVM.
  brew_tool llvm # -v --with-clang

  # osquery tool dependencies
  brew_tool libtool
  brew_tool bison

  # Install custom formulas, build with LLVM/clang.
  local_brew_dependency boost
  local_brew_dependency asio
  local_brew_dependency cpp-netlib
  local_brew_dependency google-benchmark

  brew_dependency lz4
  brew_dependency snappy
  brew_dependency sleuthkit
  brew_dependency libmagic

  local_brew_dependency thrift
  local_brew_dependency rocksdb
  local_brew_dependency gflags
  local_brew_dependency aws-sdk-cpp
  local_brew_dependency yara
  local_brew_dependency glog

  # This begins the linux-specific dependencies.
  # This provides the libblkid libraries.
  brew_dependency util-linux

  local_brew_dependency libdevmapper
  local_brew_dependency libaptpkg
  local_brew_dependency libiptables
  local_brew_dependency libgcrypt
  local_brew_dependency libcryptsetup
  local_brew_dependency libudev
  local_brew_dependency libaudit
  local_brew_dependency libdpkg
}
