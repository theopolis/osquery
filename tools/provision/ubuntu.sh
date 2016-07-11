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
  package autotools-dev
  package autopoint
  package python-dev
  package python-pip
  package realpath

  # GCC 5x bootstrapping.
  core_brew_tool patchelf
  core_brew_tool zlib
  core_brew_tool binutils
  core_brew_tool linux-headers

  # Build a bottle of glibc
  local_brew_tool glibc
  $BREW postinstall glibc

  local_brew_tool xz
  core_brew_tool gmp
  brew_tool gpatch
  core_brew_tool mpfr
  core_brew_tool libmpc
  core_brew_tool isl
  brew_tool berkeley-db

  # GCC 5x.
  core_brew_tool gcc

  set_cc gcc
  set_cxx g++

  # GCC-compiled (C) dependencies.
  brew_tool pkg-config

  # Build a bottle for ncurses
  local_brew_tool ncurses

  local_brew_tool bzip2
  brew_tool unzip
  local_brew_tool readline
  brew_tool sqlite
  core_brew_tool makedepend

  # Build a bottle for perl and openssl
  local_brew_tool perl --without-test
  local_brew_tool openssl

  brew_tool libxml2
  brew_tool libedit
  brew_tool libidn

  # osquery tool dependencies
  brew_tool libtool
  brew_tool m4
  brew_tool bison
  local_brew_tool libgpg-error
  brew_tool popt
  brew_tool autoconf
  brew_tool automake

  # LLVM dependencies.
  local_brew_tool curl
  local_brew_tool python
  core_brew_tool cmake --ignore-dependencies

  # LLVM.
  local_brew_tool llvm -v --with-clang --with-clang-extra --with-compiler-rt

  # Install custom formulas, build with LLVM/clang.
  local_brew_dependency boost

  # asio needs gdbm perl autoconf automake
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

  # This begins the linux-specific dependencies.
  # This provides the libblkid libraries.
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
