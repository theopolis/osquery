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
  brew_tool pkg-config
  brew_tool ncurses
  brew_tool bzip2
  brew_tool unzip
  brew_tool readline
  brew_tool sqlite
  brew_tool makedepend
  brew_tool openssl
  brew_tool libxml2
  brew_tool libedit
  brew_tool libidn

  # osquery tool dependencies
  brew_tool libtool
  brew_tool bison
  brew_tool libgpg-error
  brew_tool popt
  brew_tool autoconf
  brew_tool automake

  # LLVM dependencies.
  # brew_tool curl
  # brew_tool perl --without-test
  # brew_tool python
  brew_tool cmake --ignore-dependencies

  # LLVM.
  brew_tool llvm -v --with-clang --with-clang-extra --with-compiler-rt

  # Now that the compiler toolchain is modern, unlink libs.
  # $BREW unlink zlib
  $BREW unlink glibc
  # $BREW unlink bzip2
  # $BREW unlink sqlite

  set_cc clang
  set_cxx clang++

  # Install custom formulas, build with LLVM/clang.
  local_brew_dependency boost

  # asio needs gdbm perl autoconf automake
  local_brew_dependency asio --ignore-dependencies
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
