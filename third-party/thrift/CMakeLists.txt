# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(thrifMain)
  set(name "thrift")
  set(anchor_file "lib/libthrift.a")

  set(additional_library
    "lib/libthriftz.a"
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/parse.lib")

    set(additional_libraries
      lib/thriftzmt.lib
      lib/thriftmt.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})

  target_link_libraries("thirdparty_${name}" INTERFACE thirdparty_boost)

  set(dependencies boost openssl)
  definePrebuildProject(${name}
    URL https://github.com/apache/thrift/archive/0.11.0.tar.gz
    SHA256 0e324569321a1b626381baabbb98000c8dd3a59697292dbcc71e67135af0fefd
    PATCHES libthrift-0.11.0-1.patch
    DEPENDS ${dependencies}
    CONFIGURE
      export CXXFLAGS=-Wno-error\ $ENV{CXXFLAGS} &&
      export CPPFLAGS=-DOPENSSL_NO_SSL3\ $ENV{CPPFLAGS} &&
      ./bootstrap.sh &&
      ./configure
        --prefix=<INSTALL_DIR>
        --disable-shared
        --enable-static
        --disable-tests
        --without-ruby
        --without-php_extension
        --without-haskell
        --without-java
        --without-perl
        --without-php
        --without-erlang
        --without-go
        --without-qt
        --without-qt4
        --without-qt5
        --without-d
        --without-lua
        --without-dart
        --without-nodejs
        --without-rs
        --without-python
        --with-cpp
        --with-libevent=no
        --enable-tutorial=no
        --with-openssl=<INSTALL_DIR>
        --with-boost=<INSTALL_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
    BUILD_IN_SOURCE ON
  )
endfunction()

thrifMain()
