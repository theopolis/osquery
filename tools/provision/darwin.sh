#!/usr/bin/env bash

#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.

function distro_main() {
  type pip >/dev/null 2>&1 || {
    fatal "could not find pip. please install it using 'sudo easy_install pip'";
  }

  brew_tool xz
  # brew_tool perl --without-test # Needs -lgdbm
  brew_tool sphinx-doc

  brew_dependency sqlite
  brew_dependency readline
  # brew_dependency zlib this is not available on Darwin
  # brew_dependency bzip2 this is also not available on Darwin
  brew_dependency openssl

  $BREW link --force openssl

  brew_tool pkg-config
  brew_tool cmake

  local_brew_dependency boost
  local_brew_dependency asio
  local_brew_dependency cpp-netlib

  brew_dependency google-benchmark
  brew_dependency snappy
  brew_dependency sleuthkit
  brew_dependency libmagic

  # Yara will pull in lz4, bz2, and libpcre.

  local_brew_dependency yara
  local_brew_dependency glog
  local_brew_dependency thrift
  local_brew_dependency rocksdb
  local_brew_dependency gflags
  local_brew_dependency aws-sdk-cpp
}
