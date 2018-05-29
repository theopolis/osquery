#!/usr/bin/env bash

#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under both the Apache 2.0 license (found in the
#  LICENSE file in the root directory of this source tree) and the GPLv2 (found
#  in the COPYING file in the root directory of this source tree).
#  You may select, at your option, one of the above-listed licenses.

set -e

# Helpful defines for the provisioning process.
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$SCRIPT_DIR/lib.sh"

# Setup the osquery dependency directory.
# One can use a non-build location using OSQUERY_DEPS=/path/to/deps
if [[ ! -z "$OSQUERY_DEPS" ]]; then
  DEPS_DIR="$OSQUERY_DEPS"
else
  DEPS_DIR="/usr/local/osquery"
fi

function main() {
  ACTION=$1

  if [[ "$ACTION" = "on" ]]; then
    if [ -d "$DEPS_DIR/NativeCellar" ]; then
      echo "ARM DEPs build is already enabled"
      return
    fi

    echo "ARM DEPs build turning on..."
    if [ ! -d "$DEPS_DIR/ArmCellar" ]; then
      mkdir -p "$DEPS_DIR/ArmCellar"
    fi

    mv "$DEPS_DIR/Cellar" "$DEPS_DIR/NativeCellar"

    # Stage 1 runtime (Homebrew).
    ln -sf "$DEPS_DIR/NativeCellar/linux-headers" "$DEPS_DIR/ArmCellar/linux-headers"
    ln -sf "$DEPS_DIR/NativeCellar/zlib" "$DEPS_DIR/ArmCellar/zlib"

    # State 1 runtime (custom).
    ln -sf "$DEPS_DIR/NativeCellar/glibc-legacy" "$DEPS_DIR/ArmCellar/glibc-legacy"
    ln -sf "$DEPS_DIR/NativeCellar/zlib-legacy" "$DEPS_DIR/ArmCellar/zlib-legacy"

    # Stage 1.
    ln -sf "$DEPS_DIR/NativeCellar/gcc" "$DEPS_DIR/ArmCellar/gcc"

    # Stage 2 and ARM built-ins.
    ln -sf "$DEPS_DIR/NativeCellar/llvm" "$DEPS_DIR/ArmCellar/llvm"
    ln -sf "$DEPS_DIR/NativeCellar/libcpp" "$DEPS_DIR/ArmCellar/libcpp"

    # Not sure if this should be here.
    # ln -sf "$DEPS_DIR/NativeCellar/libcpp-arm" "$DEPS_DIR/ArmCellar/libcpp-arm"

    # Runtime tool: pythom
    ln -sf "$DEPS_DIR/NativeCellar/python" "$DEPS_DIR/ArmCellar/python"
    # Runtime tool: cmake
    ln -sf "$DEPS_DIR/NativeCellar/cmake" "$DEPS_DIR/ArmCellar/cmake"
    # Runtime tool: ccache
    ln -sf "$DEPS_DIR/NativeCellar/ccache" "$DEPS_DIR/ArmCellar/ccache"
    # Runtime tool: thrift
    ln -sf "$DEPS_DIR/NativeCellar/thrift" "$DEPS_DIR/ArmCellar/thrift"
    # Runtime tool: file
    ln -sf "$DEPS_DIR/NativeCellar/libmagic" "$DEPS_DIR/ArmCellar/libmagic"

    mv "$DEPS_DIR/ArmCellar" "$DEPS_DIR/Cellar"
  else
    if [ ! -d "$DEPS_DIR/NativeCellar" ]; then
      echo "ARM DEPs build is already disabled"
      return
    fi

    echo "ARM DEPs build turning off..."
    mv "$DEPS_DIR/Cellar" "$DEPS_DIR/ArmCellar"
    mv "$DEPS_DIR/NativeCellar" "$DEPS_DIR/Cellar"
  fi
}

main $1