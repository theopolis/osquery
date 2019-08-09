# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(gflagsMain)
  set(BUILD_gflags_nothreads_LIB false CACHE BOOL "" FORCE)
  set(BUILD_gflags_LIB true CACHE BOOL "" FORCE)

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

    target_compile_options(gflags_static PUBLIC
      ${flag_list}
    )
  endforeach()

  add_library(thirdparty_gflags INTERFACE)
  target_link_libraries(thirdparty_gflags INTERFACE
    gflags_static
  )

  target_include_directories(thirdparty_gflags INTERFACE
    "${CMAKE_CURRENT_BINARY_DIR}/submodule/include"
  )
endfunction()

gflagsMain()
