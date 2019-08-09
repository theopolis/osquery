# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(googleLogMain)
  set(disabled_option_list
    WITH_TLS
    WITH_GFLAGS
  )

  set(enabled_option_list
    HAVE_LIB_GFLAGS
    WITH_THREADS
  )

  foreach(option_name ${disabled_option_list})
    set("${option_name}" false CACHE BOOL "" FORCE)
  endforeach()

  foreach(option_name ${enabled_option_list})
    set("${option_name}" true CACHE BOOL "" FORCE)
  endforeach()

  set(library_root "${CMAKE_CURRENT_SOURCE_DIR}/src")
  add_subdirectory("${library_root}" "${CMAKE_CURRENT_BINARY_DIR}/submodule" EXCLUDE_FROM_ALL)
  
  set(compile_options_target_list
    global_settings
    cxx_settings
    thirdparty_source_module_warnings
  )

  foreach(compile_options_target ${compile_options_target_list})
    get_target_property(flag_list
      "${compile_options_target}"
      INTERFACE_COMPILE_OPTIONS
    )

    target_compile_options(glog PUBLIC
      ${flag_list}
    )
  endforeach()

  get_target_property(gflags_include_directory thirdparty_gflags INTERFACE_INCLUDE_DIRECTORIES)
  target_include_directories(glog PRIVATE "${gflags_include_directory}")

  add_library(thirdparty_glog INTERFACE)
  target_link_libraries(thirdparty_glog INTERFACE
    glog
    thirdparty_gflags
  )
endfunction()

googleLogMain()
