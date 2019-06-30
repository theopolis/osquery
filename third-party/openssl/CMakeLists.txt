# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(opensslMain)
  set(name "openssl")

  set(anchor_file "lib/libssl.a")

  set(additional_lib
    lib/libcrypto.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libeay32.lib")

    set(additional_lib
      lib/ssleay32.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_lib})

  if(DEFINED PLATFORM_DARWIN)
    set(configure_targets darwin64-x86_64-cc enable-ec_nistp_64_gcc_128)
  elseif(DEFINED PLATFORM_LINUX)
    set(configure_targets linux-x86_64)
  endif()

  definePrebuildProject(${name}
    URL https://www.openssl.org/source/openssl-1.0.2o.tar.gz
    SHA256
    CONFIGURE
      perl ./Configure --prefix=<INSTALL_DIR>
        --openssldir=<INSTALL_DIR>/etc/openssl
        no-ssl2
        no-ssl3
        no-asm
        no-shared
        no-weak-ssl-ciphers
        zlib-dynamic
        enable-cms
        "$ENV{CFLAGS}"
        ${configure_targets}
    BUILD
      mkdir -p <INSTALL_DIR>/etc/openssl &&
      $(MAKE) depend &&
      $(MAKE)
    INSTALL
      $(MAKE) install
    BUILD_IN_SOURCE ON
  )
endfunction()

opensslMain()
