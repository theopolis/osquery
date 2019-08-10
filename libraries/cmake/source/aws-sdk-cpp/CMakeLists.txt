# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(awsSdkCppMain)
  # Set the AWS sdk parameters in cache
  set(enabled_option_list
    ZLIB_FOUND
    OPENSSL_FOUND
    STATIC_LINKING
    NO_HTTP_CLIENT
    MINIMIZE_SIZE
  )

  set(disabled_option_list
    ENABLE_TESTING
    AUTORUN_UNIT_TESTS
  )

  foreach(option_name ${enabled_option_list})
    set("${option_name}" true CACHE BOOL "" FORCE)
  endforeach()

  foreach(option_name ${disabled_option_list})
    set("${option_name}" false CACHE BOOL "" FORCE)
  endforeach()

  # Pass the required dependencies
  get_target_property(zlib_include_directory thirdparty_zlib INTERFACE_INCLUDE_DIRECTORIES)

  set(ZLIB_LIBRARY "$<TARGET_FILE:thirdparty_zlib>" CACHE STRING "" FORCE)
  set(ZLIB_INCLUDE_DIR "${zlib_include_directory}" CACHE STRING "" FORCE)

  get_target_property(libcrypto_library_path thirdparty_intermediate_libcrypto IMPORTED_LOCATION)
  get_target_property(libssl_library_path thirdparty_intermediate_libssl IMPORTED_LOCATION)
  get_target_property(openssl_include_directory thirdparty_intermediate_libssl INTERFACE_INCLUDE_DIRECTORIES)

  set(OPENSSL_CRYPTO_LIBRARY "${libcrypto_library_path}" CACHE STRING "" FORCE)
  set(OPENSSL_SSL_LIBRARY "${libssl_library_path}" CACHE STRING "" FORCE)
  set(OPENSSL_INCLUDE_DIR "${openssl_include_directory}" CACHE STRING "" FORCE)

  set(BUILD_ONLY "firehose;kinesis;sts;ec2" CACHE STRING "" FORCE)

  # Actually include the AWS sdk folder
  set(library_root "${CMAKE_CURRENT_SOURCE_DIR}/src")
  add_subdirectory("${library_root}" "${CMAKE_CURRENT_BINARY_DIR}/submodule" EXCLUDE_FROM_ALL)

  add_dependencies(aws-cpp-sdk-core
    thirdparty_openssl
    thirdparty_zlib
  )

  # Transfer at least some of the compilation flags we want
  set(compile_options_target_list
    global_settings
    cxx_settings
    thirdparty_source_module_warnings
  )

  foreach(library_name ${BUILD_ONLY})
    foreach(compile_options_target ${compile_options_target_list})
      get_target_property(flag_list
        "${compile_options_target}"
        INTERFACE_COMPILE_OPTIONS
      )

      target_compile_options("aws-cpp-sdk-${library_name}" PUBLIC
        ${flag_list}
      )
    endforeach()
  endforeach()

  # Generate the final interface target, adding the core library
  add_library(thirdparty_aws-sdk-cpp INTERFACE)

  foreach(library_name ${BUILD_ONLY} core)
    target_link_libraries(thirdparty_aws-sdk-cpp INTERFACE
      "aws-cpp-sdk-${library_name}"
    )
  endforeach()
endfunction()

awsSdkCppMain()
