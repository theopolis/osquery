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
endfunction()

awsSdkCppMain()
