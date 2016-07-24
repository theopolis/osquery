#!/usr/bin/env bash

#  Copyright (c) 2014-present, Facebook, Inc.
#  All rights reserved.
#
#  This source code is licensed under the BSD-style license found in the
#  LICENSE file in the root directory of this source tree. An additional grant
#  of patent rights can be found in the PATENTS file in the same directory.

# 1: Path to install brew into
# 2: Linux or Darwin
function setup_brew() {
  if [[ "$2" == "linux" ]]; then
    BREW=https://github.com/Linuxbrew/brew
  else
    BREW=https://github.com/Homebrew/brew
  fi

  # Check if DEPS directory exists.
  DEPS="$1"
  if [[ ! -d "$DEPS" ]]; then
    log "the build directory: $DEPS does not exist"
    sudo mkdir "$DEPS"
    sudo chown $USER "$DEPS"
  fi

  # Checkout new brew in local deps dir
  if [[ ! -d "$DEPS/.git" ]]; then
    log "setting up new brew in $DEPS"
    git clone $BREW .
    log "installing local tap: homebrew-osquery-local"
    mkdir -p "$DEPS/Library/Taps/osquery/"
    ln -sf "$FORMULA_DIR" "$DEPS/Library/Taps/osquery/homebrew-osquery-local" 
  else
    log "checking for updates to brew"
    #git pull
  fi

  export HOMEBREW_MAKE_JOBS=$THREADS
  export HOMEBREW_NO_EMOJI=1
  export BREW="$DEPS/bin/brew"
  log "installing homebrew dupes"
  $BREW tap homebrew/dupes
}

# json_element JSON STRUCT
#   1: JSON blob
#   2: parse structure
function json_element() {
  CMD="import json,sys;obj=json.load(sys.stdin);print ${2}"
  RESULT=`(echo "${1}" | python -c "${CMD}") 2>&1 || echo 'NAN'`
  echo $RESULT
}

# brew_tool NAME
#   This will install from brew.
function brew_tool() {
  TOOL=$1
  shift

  if [[ -z "$OSQUERY_BUILD_DEPS" && -z "$OSQUERY_DEPS_ONETIME" ]]; then
    return
  fi
  unset OSQUERY_DEPS_ONETIME
  export HOMEBREW_OPTIMIZATION_LEVEL=-Os
  log "brew tool $TOOL"
  $BREW install --force-bottle --ignore-dependencies $@ "$TOOL"
}

function core_brew_tool() {
  export OSQUERY_DEPS_ONETIME=1
  brew_tool $@
}

function local_brew_link() {
  TOOL=$1
  if [[ ! -z "$OSQUERY_BUILD_DEPS" ]]; then
    $BREW link --force "${FORMULA_DIR}/${TOOL}.rb"
  fi
}

function local_brew_postinstall() {
  TOOL=$1
  if [[ ! -z "$OSQUERY_BUILD_DEPS" ]]; then
    $BREW postinstall "${FORMULA_DIR}/${TOOL}.rb"
  fi
}

# local_brew_tool NAME
#   This will build or install from a local formula.
#   If the caller did not request a from-source build then osquery-hosted bottles are used.
function local_brew_tool() {
  TOOL=$1
  shift

  export HOMEBREW_OPTIMIZATION_LEVEL=-Os
  log "brew (build) tool $TOOL"
  ARGS="$@"
  if [[ ! -z "$OSQUERY_BUILD_DEPS" ]]; then
    ARGS="$ARGS --build-bottle --ignore-dependencies"
    ARGS="$ARGS --env=legacy"
  else
    ARGS="--ignore-dependencies --force-bottle"
  fi
  $BREW install $ARGS "${FORMULA_DIR}/${TOOL}.rb"
}

# local_brew NAME
#   1: formula name
function local_brew_dependency() {
  TOOL="$1"
  shift

  FORMULA="${FORMULA_DIR}/$TOOL.rb"
  INFO=`$BREW info --json=v1 "${FORMULA}"`
  INSTALLED=$(json_element "${INFO}" 'obj[0]["linked_keg"]')
  STABLE=$(json_element "${INFO}" 'obj[0]["versions"]["stable"]')

  # Could improve this detection logic to remove from-bottle.
  FROM_BOTTLE=false
  ARGS="$@"
  if [[ ! -z "$OSQUERY_BUILD_DEPS" ]]; then
    ARGS="$ARGS -v --build-bottle --cc=clang --ignore-dependencies"
    ARGS="$ARGS --env=std"
  else
    ARGS="--ignore-dependencies --force-bottle"
  fi

  export HOMEBREW_OPTIMIZATION_LEVEL=-Os
  if [[ "${INSTALLED}" = "NAN" || "${INSTALLED}" = "None" ]]; then
    log "brew local package $TOOL installing new version: ${STABLE}"
    $BREW install $ARGS "${FORMULA}"
  elif [[ ! "${INSTALLED}" = "${STABLE}" || "${FROM_BOTTLE}" = "true" ]]; then
    log "brew local package $TOOL upgrading to new version: ${STABLE}"
    $BREW uninstall "${FORMULA}"
    $BREW install $ARGS "${FORMULA}"
  else
    log "brew local package $TOOL is already install: ${STABLE}"
  fi
}

function package() {
  if [[ $FAMILY = "debian" ]]; then
    INSTALLED=`dpkg-query -W -f='${Status} ${Version}\n' $1 || true`
    if [[ -n "$INSTALLED" && ! "$INSTALLED" = *"unknown ok not-installed"* ]]; then
      log "$1 is already installed. skipping."
    else
      log "installing $1"
      sudo DEBIAN_FRONTEND=noninteractive apt-get install $1 -y --no-install-recommends
    fi
  elif [[ $FAMILY = "redhat" ]]; then
    if [[ ! -n "$(rpm -V $1)" ]]; then
      log "$1 is already installed. skipping."
    else
      log "installing $1"
      if [[ $OS = "fedora" ]]; then
        sudo dnf install $1 -y
      else
        sudo yum install $1 -y
      fi
    fi
  elif [[ $OS = "darwin" ]]; then
    if [[ -n "$(brew list | grep $1)" ]]; then
      log "$1 is already installed. skipping."
    else
      log "installing $1"
      unset LIBNAME
      unset HOMEBREW_BUILD_FROM_SOURCE
      export HOMEBREW_MAKE_JOBS=$THREADS
      export HOMEBREW_NO_EMOJI=1
      HOMEBREW_ARGS=""
      if [[ $1 = "rocksdb" ]]; then
        # Build RocksDB from source in brew
        export LIBNAME=librocksdb_lite
        export HOMEBREW_BUILD_FROM_SOURCE=1
        HOMEBREW_ARGS="--build-bottle --with-lite"
      elif [[ $1 = "gflags" ]]; then
        HOMEBREW_ARGS="--build-bottle --with-static"
      elif [[ $1 = "libressl" ]]; then
        HOMEBREW_ARGS="--build-bottle"
      elif [[ $1 = "aws-sdk-cpp" ]]; then
        HOMEBREW_ARGS="--build-bottle --with-static --without-http-client"
      fi
      if [[ "$2" = "devel" ]]; then
        HOMEBREW_ARGS="${HOMEBREW_ARGS} --devel"
      fi
      brew install -v $HOMEBREW_ARGS $1 || brew upgrade -v $HOMEBREW_ARGS $1
    fi
  elif [[ $OS = "freebsd" ]]; then
    if pkg info -q $1; then
      log "$1 is already installed. skipping."
    else
      log "installing $1"
      sudo pkg install -y $1
    fi
  elif [[ $OS = "arch" ]]; then
    if pacman -Qq $1 >/dev/null; then
      log "$1 is already installed. skipping."
    else
      log "installing $1"
      sudo pacman -S --noconfirm $1
    fi
  fi
}

function gem_install() {
  if [[ -n "$(gem list | grep $1)" ]]; then
    log "$1 is already installed. skipping."
  else
    sudo gem install $@
  fi
}

function check() {
  CMD="$1"
  DISTRO_BUILD_DIR="$2"
  platform OS

  if [[ $OS = "darwin" ]]; then
    HASH=`shasum "$0" | awk '{print $1}'`
  elif [[ $OS = "freebsd" ]]; then
    HASH=`sha1 -q "$0"`
  else
    HASH=`sha1sum "$0" | awk '{print $1}'`
  fi

  if [[ "$CMD" = "build" ]]; then
    echo $HASH > "build/$DISTRO_BUILD_DIR/.provision"
    if [[ ! -z "$SUDO_USER" ]]; then
      chown $SUDO_USER "build/$DISTRO_BUILD_DIR/.provision" > /dev/null 2>&1 || true
    fi
    return
  elif [[ ! "$CMD" = "check" ]]; then
    return
  fi

  if [[ "$#" < 2 ]]; then
    echo "Usage: $0 (check|build) BUILD_PATH"
    exit 1
  fi

  CHECKPOINT=`cat $DISTRO_BUILD_DIR/.provision 2>&1 &`
  if [[ ! $HASH = $CHECKPOINT ]]; then
    echo "Requested dependencies may have changed, run: make deps"
    exit 1
  fi
  exit 0
}
