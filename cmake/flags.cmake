include(CheckPIESupported)
check_pie_supported()
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_LINK_SEARCH_START_STATIC OFF)
set(CMAKE_LINK_SEARCH_END_STATIC OFF)

function(setupBuildFlags)
  add_library(cxx_settings INTERFACE)
  add_library(c_settings INTERFACE)

  target_compile_features(cxx_settings INTERFACE cxx_std_14)
  target_compile_features(c_settings INTERFACE c_std_11)

  if(DEFINED PLATFORM_POSIX)

    set(posix_common_compile_options
      -Qunused-arguments
      -Wno-shadow-field
      -Wall
      -Wextra
      -Wno-unused-local-typedef
      -Wno-deprecated-register
      -Wno-unknown-warning-option
      -Wstrict-aliasing
      -Wno-missing-field-initializers
      -Wchar-subscripts
      -Wpointer-arith
      -Wformat
      -Wformat-security
      -Werror=format-security
      -Wuseless-cast
      -Wno-zero-length-array
      -Wno-unused-parameter
      -Wno-gnu-case-range
      -fpermissive
      -fstack-protector-all
      -fdata-sections
      -ffunction-sections
      -fvisibility=hidden
      -fvisibility-inlines-hidden
      -fno-limit-debug-info
      -pipe
      -pedantic
    )

    if(NOT "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
      list(APPEND posix_common_compile_options INTERFACE -Oz)
    endif()

    set(osquery_posix_common_defines
      POSIX=1
      OSQUERY_POSIX=1
    )

    set(posix_cxx_compile_options
      -Wno-c++11-extensions
      -Woverloaded-virtual
      -Wnon-virtual-dtor
      -Weffc++
    )

    set(posix_cxx_link_options
      -ldl
    )

    set(posix_c_compile_options
      -Wno-c99-extensions
    )

    target_compile_options(cxx_settings INTERFACE
      ${posix_common_compile_options}
      ${posix_cxx_compile_options}
    )
    target_link_options(cxx_settings INTERFACE
      ${posix_common_link_options}
      ${posix_cxx_link_options}
    )
    target_link_libraries(cxx_settings INTERFACE
      ${posix_cxx_libraries}
    )

    target_compile_options(c_settings INTERFACE
      ${posix_common_compile_options}
      ${posix_c_compile_options}
    )

    list(APPEND osquery_defines ${osquery_posix_common_defines})


    if(DEFINED PLATFORM_LINUX)
      set(osquery_linux_common_defines
        LINUX=1
        OSQUERY_LINUX=1
        OSQUERY_BUILD_DISTRO=centos7
        OSQUERY_BUILD_PLATFORM=linux
      )

      set(osquery_linux_common_link_options
        -Wl,-z,relro,-z,now
        -Wl,--build-id=sha1
      )

      set(linux_cxx_link_options
        --no-undefined
        -lresolv
        -pthread
      )

      set(linux_cxx_link_libraries
        c++abi
        rt
        dl
      )

      list(APPEND osquery_defines ${osquery_linux_common_defines})
      target_link_options(cxx_settings INTERFACE
        ${osquery_linux_common_link_options}
        ${linux_cxx_link_options}
      )

      target_link_options(c_settings INTERFACE
        ${osquery_linux_common_link_options}
      )

      target_link_libraries(cxx_settings INTERFACE
        ${linux_cxx_link_libraries}
      )
    elseif(DEFINED PLATFORM_MACOS)
      set(macos_cxx_compile_options
        -x objective-c++
        -fobjc-arc
        -Wabi-tag
        -stdlib=libc++
      )

      set(macos_cxx_link_options
        "SHELL:-framework AppKit"
        "SHELL:-framework Foundation"
        "SHELL:-framework CoreServices"
        "SHELL:-framework CoreFoundation"
        "SHELL:-framework CoreWLAN"
        "SHELL:-framework CoreGraphics"
        "SHELL:-framework DiskArbitration"
        "SHELL:-framework IOKit"
        "SHELL:-framework OpenDirectory"
        "SHELL:-framework Security"
        "SHELL:-framework ServiceManagement"
        "SHELL:-framework SystemConfiguration"
        -stdlib=libc++
        -lresolv
      )

      set(macos_cxx_link_libraries
        iconv
        cups
        bsm
        xar
        c++abi
      )

      set(osquery_macos_common_defines
        APPLE=1
        DARWIN=1
        BSD=1
        OSQUERY_BUILD_PLATFORM=darwin
        OSQUERY_BUILD_DISTRO=10.12
      )

      target_compile_options(cxx_settings INTERFACE
        ${macos_cxx_compile_options}
      )
      target_link_options(cxx_settings INTERFACE
        ${macos_cxx_link_options}
      )
      target_link_libraries(cxx_settings INTERFACE
        ${macos_cxx_link_libraries}
      )

      list(APPEND osquery_defines ${osquery_macos_common_defines})
    else()
      message(FATAL_ERROR "Platform not supported!")
    endif()

    if(OSQUERY_NO_DEBUG_SYMBOLS AND
      ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug" OR
       "${CMAKE_BUILD_TYPE}" STREQUAL "RelWithDebInfo"))
      target_compile_options(cxx_settings INTERFACE -g0)
      target_compile_options(c_settings INTERFACE -g0)
    endif()

    if(OSQUERY_ENABLE_ADDRESS_SANITIZER)
      target_compile_options(cxx_settings INTERFACE
        -fsanitize=address,fuzzer-no-link
        -fsanitize-coverage=edge,indirect-calls
      )
      target_compile_options(c_settings INTERFACE
        -fsanitize=address,fuzzer-no-link
        -fsanitize-coverage=edge,indirect-calls
      )

      # Require at least address (may be refactored out)
      target_link_options(cxx_settings INTERFACE
        -fsanitize=address
      )
    endif()
  elseif(DEFINED PLATFORM_WINDOWS)

    set(windows_common_compile_options
      "$<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:/Z7;/Gs;/GS>"
      "$<$<CONFIG:Debug>:/Od;/UNDEBUG>$<$<NOT:$<CONFIG:Debug>>:/Ot>"
      /MT
      /EHs
      /W3
      /guard:cf
      /bigobj
    )

    set(windows_common_link_options
      /SUBSYSTEM:CONSOLE
      /LTCG
      ntdll.lib
      ole32.lib
      oleaut32.lib
      ws2_32.lib
      iphlpapi.lib
      netapi32.lib
      rpcrt4.lib
      shlwapi.lib
      version.lib
      wtsapi32.lib
      wbemuuid.lib
      secur32.lib
      taskschd.lib
      dbghelp.lib
      dbgeng.lib
      bcrypt.lib
      crypt32.lib
      wintrust.lib
      setupapi.lib
      advapi32.lib
      userenv.lib
      wevtapi.lib
      shell32.lib
      gdi32.lib
    )

    set(osquery_windows_common_defines
      WIN32=1
      WINDOWS=1
      WIN32_LEAN_AND_MEAN
      OSQUERY_WINDOWS=1
      OSQUERY_BUILD_PLATFORM=windows
      OSQUERY_BUILD_DISTRO=10
      BOOST_CONFIG_SUPPRESS_OUTDATED_MESSAGE=1
    )

    set(windows_common_defines
      "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>"
      _WIN32_WINNT=_WIN32_WINNT_WIN7
      NTDDI_VERSION=NTDDI_WIN7
    )

    set(windows_cxx_compile_options
      /Zc:inline-
    )

    set(windows_cxx_defines
      BOOST_ALL_NO_LIB
      BOOST_ALL_STATIC_LINK
    )

    target_compile_options(cxx_settings INTERFACE
      ${windows_common_compile_options}
      ${windows_cxx_compile_options}
    )
    target_compile_definitions(cxx_settings INTERFACE
      ${windows_common_defines}
      ${windows_cxx_defines}
    )
    target_link_options(cxx_settings INTERFACE
      ${windows_common_link_options}
    )

    target_compile_options(c_settings INTERFACE
      ${windows_common_compile_options}
    )
    target_compile_definitions(c_settings INTERFACE
      ${windows_common_defines}
    )
    target_link_options(c_settings INTERFACE
      ${windows_common_link_options}
    )

    list(APPEND osquery_defines ${osquery_windows_common_defines})

    # Remove some flags from the default ones to avoid "overriding" warnings or unwanted results.
    if(DEFINED PLATFORM_WINDOWS AND "${CMAKE_GENERATOR}" STREQUAL "Ninja")
      string(REPLACE "/MD" "" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
      string(REPLACE "/MD" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
      string(REPLACE "/MD" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
      string(REPLACE "/MD" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

      string(REPLACE "/Zi" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
      string(REPLACE "/Zi" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")

      # This must be removed, because passing /EHs doesn't override it
      string(REPLACE "/EHsc" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")

      overwrite_cache_variable("CMAKE_C_FLAGS_RELEASE" STRING "${CMAKE_C_FLAGS_RELEASE}")
      overwrite_cache_variable("CMAKE_C_FLAGS_RELWITHDEBINFO" STRING "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
      overwrite_cache_variable("CMAKE_CXX_FLAGS_RELEASE" STRING "${CMAKE_CXX_FLAGS_RELEASE}")
      overwrite_cache_variable("CMAKE_CXX_FLAGS_RELWITHDEBINFO" STRING "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
      overwrite_cache_variable("CMAKE_CXX_FLAGS" STRING "${CMAKE_CXX_FLAGS}")
    endif()
  else()
    message(FATAL_ERROR "Platform not supported!")
  endif()

  add_library(osquery_cxx_settings INTERFACE)
  target_link_libraries(osquery_cxx_settings INTERFACE
    cxx_settings
  )

  target_compile_definitions(osquery_cxx_settings INTERFACE
    ${osquery_defines}
  )


  add_library(osquery_c_settings INTERFACE)
  target_link_libraries(osquery_c_settings INTERFACE
    c_settings
  )

  target_compile_definitions(osquery_c_settings INTERFACE
    ${osquery_defines}
  )

endfunction()

setupBuildFlags()
