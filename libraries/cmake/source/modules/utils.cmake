# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13.3)

option(OSQUERY_THIRD_PARTY_SOURCE_MODULE_WARNINGS "This option can be enable to show all warnings in the source modules. Not recommended" OFF)

function(initializeGitSubmodule submodule_path)
  file(GLOB submodule_folder_contents "${submodule_path}/*")

  list(LENGTH submodule_folder_contents submodule_folder_file_count)
  if(NOT ${submodule_folder_file_count} EQUAL 0)
    set(initializeGitSubmodule_IsAlreadyCloned TRUE PARENT_SCOPE)
    return()
  endif()

  find_package(Git REQUIRED)

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" submodule update --init --recursive "${submodule_path}"
    RESULT_VARIABLE process_exit_code
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  )

  if(NOT ${process_exit_code} EQUAL 0)
    message(FATAL_ERROR "Failed to update the following git submodule: \"${submodule_path}\"")
  endif()

  set(initializeGitSubmodule_IsAlreadyCloned FALSE PARENT_SCOPE)
endfunction()

function(patchSubmoduleSourceCode patches_dir apply_to_dir)
  file(GLOB submodule_patches "${patches_dir}/*.patch")

  foreach(patch ${submodule_patches})
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" apply "${patch}"
      RESULT_VARIABLE process_exit_code
      WORKING_DIRECTORY "${apply_to_dir}"
    )

    if(NOT ${process_exit_code} EQUAL 0)
      message(FATAL_ERROR "Failed to patch the following git submodule: \"${apply_to_dir}\"")
    endif()
  endforeach()
endfunction()

function(importSourceSubmodule library_name)
  if("${library_name}" STREQUAL "modules")
    message(FATAL_ERROR "Invalid library name specified: ${library_name}")
  endif()

  message(STATUS "Importing: source/${library_name}")

  if("${ARGN}" STREQUAL "")
    set(submodule_name_list "src")
  else()
    set(submodule_name_list ${ARGN})
  endif()

  set(directory_path "${CMAKE_SOURCE_DIR}/libraries/cmake/source/${library_name}")
  foreach(submodule_name ${submodule_name_list})
    initializeGitSubmodule("${directory_path}/${submodule_name}")

    if(NOT initializeGitSubmodule_IsAlreadyCloned)
      patchSubmoduleSourceCode("${directory_path}/patches/${submodule_name}" "${directory_path}/${submodule_name}")
    endif()
  endforeach()

  if(NOT TARGET thirdparty_source_module_settings)
    add_library(thirdparty_source_module_settings INTERFACE)

    if(NOT OSQUERY_THIRD_PARTY_SOURCE_MODULE_WARNINGS)
      target_compile_options(thirdparty_source_module_settings INTERFACE
        -Wno-everything -Wno-all -Wno-error
      )
    endif()

    if(DEFINED PLATFORM_LINUX)
      target_compile_options(thirdparty_source_module_settings INTERFACE
        -Oz
        -g0
      )

      target_compile_definitions(thirdparty_source_module_settings INTERFACE
        NDEBUG
      )
    endif()
  endif()

  add_subdirectory(
    "${directory_path}"
    "${CMAKE_BINARY_DIR}/libs/src/${library_name}"
  )
endfunction()
