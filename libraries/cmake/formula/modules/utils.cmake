# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13.3)
include(ExternalProject)

set(OSQUERY_FORMULA_INSTALL_DIRECTORY "${CMAKE_BINARY_DIR}/installed_formulas")

function(importFormula library_name)
  if("${library_name}" STREQUAL "modules")
    message(FATAL_ERROR "Invalid library name specified: ${library_name}")
  endif()

  message(STATUS "Importing formula: formula/${library_name}")

  # Make sure the source folder exists
  set(project_directory_path "${CMAKE_SOURCE_DIR}/libraries/cmake/formula/${library_name}")

  if(NOT EXISTS "${project_directory_path}")
    message(FATAL_ERROR "The formula was not found: ${project_directory_path}")
  endif()

  # Create the build folder in advance
  set(build_directory_path "${CMAKE_CURRENT_BINARY_DIR}/${library_name}")

  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${build_directory_path}"
    RESULT_VARIABLE error
  )

  if(NOT ${error} EQUAL 0)
    message(FATAL_ERROR "The formula build folder could not be created: ${build_directory_path}")
  endif()

  # We need to configure the project to capture its metadata
  set(install_prefix "${OSQUERY_FORMULA_INSTALL_DIRECTORY}/${library_name}")

  if(DEFINED PLATFORM_WINDOWS)
    set(toolset_option -T "${CMAKE_GENERATOR_TOOLSET}")
  endif()

  execute_process(
    COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" ${toolset_option} "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}" "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}" "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}" "-DCMAKE_INSTALL_PREFIX:STRING=${install_prefix}" "${project_directory_path}"
    WORKING_DIRECTORY "${build_directory_path}"
    RESULT_VARIABLE error
    OUTPUT_VARIABLE std_output
    ERROR_VARIABLE std_error
  )

  if(NOT ${error} EQUAL 0)
    message(FATAL_ERROR "The ${library_name} formula could not be configured\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
  endif()

  # Get the formula metadata
  set(metadata_field_list
    metadata_version
    metadata_revision
    metadata_dependencies
    metadata_libraries
  )

  foreach(metadata_field ${metadata_field_list})
    execute_process(
      COMMAND "${CMAKE_COMMAND}" --build . --config "${CMAKE_BUILD_TYPE}" --target "${metadata_field}"
      WORKING_DIRECTORY "${build_directory_path}"
      RESULT_VARIABLE error
      OUTPUT_VARIABLE std_output
      ERROR_VARIABLE std_error
    )

    if(NOT ${error} EQUAL 0)
      message(FATAL_ERROR "Failed to acquire the metadata field ${metadata_field} for formula ${library_name}\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
    endif()

    string(FIND "${std_output}" "[" value_start_index)
    if(${value_start_index} EQUAL -1)
      message(FATAL_ERROR "Malformed metadata field ${metadata_field} for formula ${library_name}\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
    endif()

    string(FIND "${std_output}" "]" value_end_index)
    if(${value_end_index} EQUAL -1)
      message(FATAL_ERROR "Malformed metadata field ${metadata_field} for formula ${library_name}\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
    endif()

    math(EXPR value_start_index "${value_start_index} + 1")
    math(EXPR value_char_length "${value_end_index} - ${value_start_index}")

    if(${value_char_length} EQUAL 0)
      if("${metadata_field}" STREQUAL "metadata_dependencies")
        continue()
      else()
        message(FATAL_ERROR "Malformed metadata field ${metadata_field} for formula ${library_name}\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
      endif()
    endif()

    string(SUBSTRING "${std_output}" ${value_start_index} ${value_char_length} metadata_field_value)
    if("${metadata_field_value}" STREQUAL "")
      message(FATAL_ERROR "Malformed metadata field ${metadata_field} for formula ${library_name}\nstdout\n===\n${std_output}\n\n\nstderr\n===\n${std_error}")
    endif()

    set("${metadata_field}" "${metadata_field_value}")
  endforeach()

  # Generate the options necessary to pass the dependencies to the formula
  if(DEFINED metadata_dependencies)
    foreach(dependency ${metadata_dependencies})
      if(NOT TARGET "${dependency}")
        message(FATAL_ERROR "Invalid dependency specified: ${dependency}")
      endif()

      get_target_property(dependency_include_dirs "${dependency}" INTERFACE_INCLUDE_DIRECTORIES)
      if("${dependency_include_dirs}" STREQUAL "dependency_include_dirs-NOTFOUND")
        message(FATAL_ERROR "Failed to acquire the interface include directory for library ${dependency}")
      endif()

      list(APPEND formula_dependency_settings
        "-D${dependency}_INCLUDE_DIRS:STRING=${dependency_include_dirs}"
        "-D${dependency}_LIBRARIES:STRING=$<TARGET_FILE:${dependency}>"
      )
    endforeach()
  endif()

  # Generate the formula runner that will actually build the libraries
  # TODO(alessandro): Change it so we use a completely new environment
  foreach(output_lib ${metadata_libraries})
    list(APPEND output_file_list "${install_prefix}/${output_lib}")
  endforeach()

  set(log_folder_path
    "${CMAKE_BINARY_DIR}/formula_logs"
  )

  set(log_file_path
    "${log_folder_path}/${library_name}.txt"
  )

  getCompilationFlags(c c_compilation_flags)
  getCompilationFlags(cxx cxx_compilation_flags)

  add_custom_command(
    OUTPUT ${output_file_list}
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${log_folder_path}"
    COMMAND "${CMAKE_COMMAND}" -E remove -f "${log_file_path}"
    COMMAND "${CMAKE_COMMAND}" -DC_FLAGS:STRING="${c_compilation_flags}" -DCXX_FLAGS:STRING="${c_compilation_flags}" ${formula_dependency_settings} "${project_directory_path}" >> "${log_file_path}" 2>&1
    COMMAND "${CMAKE_COMMAND}" --build . --config "${CMAKE_BUILD_TYPE}" >> "${log_file_path}" 2>&1
    WORKING_DIRECTORY "${build_directory_path}"
    COMMENT "Running formula: ${library_name} (${log_file_path})"
    VERBATIM
  )

  add_custom_target("${library_name}_formula_runner"
    DEPENDS ${output_file_list}
  )

  add_dependencies("${library_name}_formula_runner"
    ${metadata_dependencies}
  )

  # Generate the imported library
  add_library("thirdparty_${library_name}" INTERFACE)

  foreach(output_lib ${metadata_libraries})
    get_filename_component(output_lib_name "${output_lib}" NAME_WE)
    set(intermediate_target_name "thirdparty_intermediate_${output_lib_name}")

    add_library("${intermediate_target_name}" STATIC IMPORTED GLOBAL)
    set_target_properties("${intermediate_target_name}" PROPERTIES IMPORTED_LOCATION
      "${install_prefix}/${output_lib}"
    )

    target_include_directories("${intermediate_target_name}" INTERFACE "${install_prefix}/include")
    target_link_libraries("thirdparty_${library_name}" INTERFACE "${intermediate_target_name}")
  endforeach()

  add_dependencies("thirdparty_${library_name}"
    "${library_name}_formula_runner"
  )

  message(STATUS "  Version: ${metadata_version}")
  message(STATUS "  Revision: ${metadata_revision}")
  message(STATUS "  Dependencies: ${metadata_dependencies}")
endfunction()

function(getCompilationFlags language output_variable)
  if("${language}" STREQUAL "c")
    set(target_name_list "c_settings")

  elseif("${language}" STREQUAL "cxx")
    set(target_name_list "cxx_settings")

  else()
    message(FATAL_ERROR "Invalid language specified. Valid options are c and cxx")
  endif()

  list(APPEND target_name_list
    global_settings
  )

  unset("${output_variable}")

  foreach(target_name ${target_name_list})
    get_target_property(compile_option_list "${target_name}" INTERFACE_COMPILE_OPTIONS)
    get_target_property(compile_def_list "${target_name}" INTERFACE_COMPILE_DEFINITIONS)

    if(NOT "${compile_option_list}" STREQUAL "compile_option_list-NOTFOUND")
      list(APPEND "${output_variable}" ${compile_option_list})
    endif()

    if(NOT "${compile_def_list}" STREQUAL "compile_def_list-NOTFOUND")
      foreach(compile_def ${compile_def_list})
        list(APPEND "${output_variable}"
          "-D${compile_def}"
        )
      endforeach()
    endif()
  endforeach()

  string(REPLACE ";" "," "${output_variable}" "${${output_variable}}")
  set("${output_variable}" "${${output_variable}}" PARENT_SCOPE)
endfunction()
