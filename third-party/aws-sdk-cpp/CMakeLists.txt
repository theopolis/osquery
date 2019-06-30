# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(awsSdkCppMain)
  set(name "aws-sdk-cpp")
  set(anchor_file lib/libaws-cpp-sdk-ec2.a)

  set(additional_libraries
    lib/libaws-cpp-sdk-firehose.a
    lib/libaws-cpp-sdk-kinesis.a
    lib/libaws-cpp-sdk-sts.a
    lib/libaws-cpp-sdk-core.a
  )

  if(DEFINED PLATFORM_WINDOWS)
    set(anchor_file "lib/libaws-cpp-sdk-ec2.a")
    set(additional_libraries
      lib/aws-cpp-sdk-firehose.lib
      lib/aws-cpp-sdk-kinesis.lib
      lib/aws-cpp-sdk-sts.lib
    )
  endif()

  importThirdPartyBinaryLibrary("${name}" "${anchor_file}" ${additional_libraries})

  set(dependencies zlib openssl boost)
  definePrebuildProject(${name}
    URL https://github.com/aws/aws-sdk-cpp/archive/1.4.55.tar.gz
    SHA256
    DEPENDS ${dependencies}
    CONFIGURE
      cmake
        -DCMAKE_C_FLAGS_RELEASE=-DNDEBUG
        -DCMAKE_CXX_FLAGS_RELEASE=-DNDEBUG
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DCMAKE_BUILD_TYPE=Release
        -DCMAKE_LIBRARY_PATH=<INSTALL_DIR>/lib
        -DZLIB_INCLUDE_DIR=<INSTALL_DIR>/include
        -DOPENSSL_INCLUDE_DIR=<INSTALL_DIR>/include
        -DOPENSSL_SSL_LIBRARY=<INSTALL_DIR>/lib/libssl.a
        -DOPENSSL_CRYPTO_LIBRARY=<INSTALL_DIR>/lib/libcrypto.a
        -DSTATIC_LINKING=1
        -DNO_HTTP_CLIENT=1
        -DMINIMIZE_SIZE=ON
        -DBUILD_SHARED_LIBS=OFF
        -DENABLE_TESTING=OFF
        -DAUTORUN_UNIT_TESTS=OFF
        -DBUILD_ONLY=firehose$<SEMICOLON>kinesis$<SEMICOLON>sts$<SEMICOLON>ec2
        <SOURCE_DIR>
    BUILD
      $(MAKE)
    INSTALL
      $(MAKE) install
  )
endfunction()

awsSdkCppMain()
