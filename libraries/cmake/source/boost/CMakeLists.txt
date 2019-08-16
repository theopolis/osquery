# Copyright (c) 2014-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed in accordance with the terms specified in
# the LICENSE file found in the root directory of this source tree.

function(boostMain)
  set(BOOST_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/src")

  generateBoostLocale()
  generateBoostPropertyTree()
  generateBoostMpl()
  generateBoostIterator()
  generateBoostCore()
  generateBoostTypeTraits()
  generateBoostSmartPtr()
  generateBoostAssert()
  generateBoostConfig()
  generateBoostContext()
  generateBoostCoroutine()
  generateBoostFilesystem()
  generateBoostRegex()
  generateBoostThread()
  generateBoostSystem()
  generateBoostPreprocessor()
  generateBoostStaticAssert()
  generateBoostDetail()
  generateBoostIo()
  generateBoostContainerHash()
  generateBoostMove()
  generateBoostBind()
  generateBoostAtomic()
  generateBoostDateTime()
  generateBoostThrowException()
  generateBoostUtility()
  generateBoostPredef()
  generateBoostLexicalCast()
  generateBoostRange()
  generateBoostConceptCheck()
  generateBoostNumeric()
  generateBoostInteger()
  generateBoostArray()
  generateBoostContainer()
  generateBoostIntrusive()
  generateBoostMath()
  generateBoostMultiprecision()
  generateBoostTokenizer()
  generateBoostChrono()
  generateBoostRatio()
  generateBoostTuple()
  generateBoostException()
  generateBoostOptional()
  generateBoostFunction()
  generateBoostTypeIndex()
  generateBoostAlgorithm()
  generateBoostUnordered()
  generateBoostFormat()
  generateBoostVariant()
  generateBoostSerialization()
  generateBoostSpirit()
  generateBoostCoroutine2()
  generateBoostAny()
  generateBoostMultiIndex()
  generateBoostForeach()
  generateBoostAsio()
  generateBoostUUID()
  generateBoostRandom()
  generateBoostBeast()
  generateBoostMp11()
  generateBoostLogic()
  generateBoostTti()
  generateBoostFunctionTypes()
  generateBoostXpressive()
  generateBoostProto()
  generateBoostFusion()
  generateBoostConversion()

  add_library(thirdparty_boost INTERFACE)

  target_link_libraries(thirdparty_boost INTERFACE
    thirdparty_boost_coroutine
    thirdparty_boost_filesystem
    thirdparty_boost_regex
    thirdparty_boost_locale
    thirdparty_boost_format
    thirdparty_boost_variant
    thirdparty_boost_serialization
    thirdparty_boost_coroutine2
    thirdparty_boost_propertytree
    thirdparty_boost_asio
    thirdparty_boost_uuid
    thirdparty_boost_beast
    thirdparty_boost_xpressive
  )
endfunction()

function(generateBoostSerialization)
  set(library_root "${BOOST_ROOT}/libs/serialization")

  add_library(thirdparty_boost_serialization STATIC
    "${library_root}/src/archive_exception.cpp"
    "${library_root}/src/basic_archive.cpp"
    "${library_root}/src/basic_iarchive.cpp"
    "${library_root}/src/basic_iserializer.cpp"
    "${library_root}/src/basic_oarchive.cpp"
    "${library_root}/src/basic_oserializer.cpp"
    "${library_root}/src/basic_pointer_iserializer.cpp"
    "${library_root}/src/basic_pointer_oserializer.cpp"
    "${library_root}/src/basic_serializer_map.cpp"
    "${library_root}/src/basic_text_iprimitive.cpp"
    "${library_root}/src/basic_text_oprimitive.cpp"
    "${library_root}/src/basic_text_wiprimitive.cpp"
    "${library_root}/src/basic_text_woprimitive.cpp"
    "${library_root}/src/basic_xml_archive.cpp"
    "${library_root}/src/basic_xml_grammar.ipp"
    "${library_root}/src/binary_iarchive.cpp"
    "${library_root}/src/binary_oarchive.cpp"
    "${library_root}/src/binary_wiarchive.cpp"
    "${library_root}/src/binary_woarchive.cpp"
    "${library_root}/src/codecvt_null.cpp"
    "${library_root}/src/extended_type_info.cpp"
    "${library_root}/src/extended_type_info_no_rtti.cpp"
    "${library_root}/src/extended_type_info_typeid.cpp"
    "${library_root}/src/polymorphic_binary_iarchive.cpp"
    "${library_root}/src/polymorphic_binary_oarchive.cpp"
    "${library_root}/src/polymorphic_iarchive.cpp"
    "${library_root}/src/polymorphic_oarchive.cpp"
    "${library_root}/src/polymorphic_text_iarchive.cpp"
    "${library_root}/src/polymorphic_text_oarchive.cpp"
    "${library_root}/src/polymorphic_text_wiarchive.cpp"
    "${library_root}/src/polymorphic_text_woarchive.cpp"
    "${library_root}/src/polymorphic_xml_iarchive.cpp"
    "${library_root}/src/polymorphic_xml_oarchive.cpp"
    "${library_root}/src/polymorphic_xml_wiarchive.cpp"
    "${library_root}/src/polymorphic_xml_woarchive.cpp"
    "${library_root}/src/stl_port.cpp"
    "${library_root}/src/text_iarchive.cpp"
    "${library_root}/src/text_oarchive.cpp"
    "${library_root}/src/text_wiarchive.cpp"
    "${library_root}/src/text_woarchive.cpp"
    "${library_root}/src/utf8_codecvt_facet.cpp"
    "${library_root}/src/void_cast.cpp"
    "${library_root}/src/xml_archive_exception.cpp"
    "${library_root}/src/xml_grammar.cpp"
    "${library_root}/src/xml_iarchive.cpp"
    "${library_root}/src/xml_oarchive.cpp"
    "${library_root}/src/xml_wgrammar.cpp"
    "${library_root}/src/xml_wiarchive.cpp"
    "${library_root}/src/xml_woarchive.cpp"
  )

  target_include_directories(thirdparty_boost_serialization SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_serialization PUBLIC
    thirdparty_boost_assert
    thirdparty_boost_core
    thirdparty_boost_integer
    thirdparty_boost_mpl
    thirdparty_boost_utility
    thirdparty_boost_typetraits
    thirdparty_boost_io
    thirdparty_boost_smartptr
    thirdparty_boost_iterator
    thirdparty_boost_spirit
    thirdparty_boost_array
    thirdparty_boost_function
  )  
endfunction()

function(generateBoostRandom)
  set(library_root "${BOOST_ROOT}/libs/random")

  add_library(thirdparty_boost_random STATIC
    "${library_root}/src/random_device.cpp"
  )

  target_include_directories(thirdparty_boost_random SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_random PUBLIC
    thirdparty_boost_core
    thirdparty_boost_system
    thirdparty_boost_throwexception
  )  
endfunction()

function(generateBoostFusion)
  set(library_root "${BOOST_ROOT}/libs/fusion")

  add_library(thirdparty_boost_fusion INTERFACE)

  target_include_directories(thirdparty_boost_fusion SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_fusion INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostLogic)
  set(library_root "${BOOST_ROOT}/libs/logic")

  add_library(thirdparty_boost_logic INTERFACE)

  target_include_directories(thirdparty_boost_logic SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_logic INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostConversion)
  set(library_root "${BOOST_ROOT}/libs/conversion")

  add_library(thirdparty_boost_conversion INTERFACE)

  target_include_directories(thirdparty_boost_conversion SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_conversion INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostXpressive)
  set(library_root "${BOOST_ROOT}/libs/xpressive")

  add_library(thirdparty_boost_xpressive INTERFACE)

  target_include_directories(thirdparty_boost_xpressive SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_xpressive INTERFACE
    thirdparty_boost_proto
    thirdparty_boost_fusion
    thirdparty_boost_conversion
  )  
endfunction()

function(generateBoostProto)
  set(library_root "${BOOST_ROOT}/libs/proto")

  add_library(thirdparty_boost_proto INTERFACE)

  target_include_directories(thirdparty_boost_proto SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_proto INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostBeast)
  set(library_root "${BOOST_ROOT}/libs/beast")

  add_library(thirdparty_boost_beast INTERFACE)

  target_include_directories(thirdparty_boost_beast SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_beast INTERFACE
    thirdparty_boost_mp11
    thirdparty_boost_logic
  )  
endfunction()

function(generateBoostMp11)
  set(library_root "${BOOST_ROOT}/libs/mp11")

  add_library(thirdparty_boost_mp11 INTERFACE)

  target_include_directories(thirdparty_boost_mp11 SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_mp11 INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostLocale)
  set(library_root "${BOOST_ROOT}/libs/locale")

  add_library(thirdparty_boost_locale STATIC
    #"${library_root}/src/encoding/codepage.cpp"
    "${library_root}/src/icu/boundary.cpp"
    "${library_root}/src/icu/codecvt.cpp"
    "${library_root}/src/icu/collator.cpp"
    "${library_root}/src/icu/conversion.cpp"
    "${library_root}/src/icu/date_time.cpp"
    "${library_root}/src/icu/formatter.cpp"
    "${library_root}/src/icu/icu_backend.cpp"
    "${library_root}/src/icu/numeric.cpp"
    "${library_root}/src/icu/time_zone.cpp"
    "${library_root}/src/shared/date_time.cpp"
    "${library_root}/src/shared/format.cpp"
    "${library_root}/src/shared/formatting.cpp"
    "${library_root}/src/shared/generator.cpp"
    "${library_root}/src/shared/ids.cpp"
    "${library_root}/src/shared/localization_backend.cpp"
    "${library_root}/src/shared/message.cpp"
    "${library_root}/src/shared/mo_lambda.cpp"
    "${library_root}/src/std/codecvt.cpp"
    "${library_root}/src/std/collate.cpp"
    "${library_root}/src/std/converter.cpp"
    "${library_root}/src/std/numeric.cpp"
    "${library_root}/src/std/std_backend.cpp"
    "${library_root}/src/util/codecvt_converter.cpp"
    "${library_root}/src/util/default_locale.cpp"
    "${library_root}/src/util/gregorian.cpp"
    "${library_root}/src/util/info.cpp"
    "${library_root}/src/util/locale_data.cpp"
  )

  if(DEFINED PLATFORM_POSIX)
    target_sources(thirdparty_boost_locale PRIVATE
      "${library_root}/src/posix/codecvt.cpp"
      "${library_root}/src/posix/collate.cpp"
      "${library_root}/src/posix/converter.cpp"
      "${library_root}/src/posix/numeric.cpp"
      "${library_root}/src/posix/posix_backend.cpp"
    )

  elseif(DEFINED PLATFORM_WINDOWS)
    target_sources(thirdparty_boost_locale PRIVATE
      "${library_root}/src/win32/collate.cpp"
      "${library_root}/src/win32/converter.cpp"
      "${library_root}/src/win32/lcid.cpp"
      "${library_root}/src/win32/numeric.cpp"
      "${library_root}/src/win32/win_backend.cpp"
    )
  endif()

  target_include_directories(thirdparty_boost_locale SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_include_directories(thirdparty_boost_locale PRIVATE
    "${library_root}/src"
    "${library_root}/src/encoding"
    "${library_root}/src/icu"
    "${library_root}/src/shared"
    "${library_root}/src/std"
    "${library_root}/src/util"
  )

  target_link_libraries(thirdparty_boost_locale PUBLIC
    thirdparty_boost_assert
    thirdparty_boost_iterator
    thirdparty_boost_typetraits
    thirdparty_boost_core
    thirdparty_boost_thread
    thirdparty_boost_unordered
  )  
endfunction()

function(generateBoostUnordered)
  set(library_root "${BOOST_ROOT}/libs/unordered")

  add_library(thirdparty_boost_unordered INTERFACE)

  target_include_directories(thirdparty_boost_unordered SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_unordered INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostFunctionTypes)
  set(library_root "${BOOST_ROOT}/libs/function_types")

  add_library(thirdparty_boost_functiontypes INTERFACE)

  target_include_directories(thirdparty_boost_functiontypes SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_functiontypes INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostTti)
  set(library_root "${BOOST_ROOT}/libs/tti")

  add_library(thirdparty_boost_tti INTERFACE)

  target_include_directories(thirdparty_boost_tti SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_tti INTERFACE
    thirdparty_boost_functiontypes
  )  
endfunction()

function(generateBoostUUID)
  set(library_root "${BOOST_ROOT}/libs/uuid")

  add_library(thirdparty_boost_uuid INTERFACE)

  target_include_directories(thirdparty_boost_uuid SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_uuid  INTERFACE
    thirdparty_boost_random
    thirdparty_boost_tti
  )  
endfunction()

function(generateBoostAsio)
  set(library_root "${BOOST_ROOT}/libs/asio")

  add_library(thirdparty_boost_asio INTERFACE)

  target_include_directories(thirdparty_boost_asio SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_asio INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostAny)
  set(library_root "${BOOST_ROOT}/libs/any")

  add_library(thirdparty_boost_any INTERFACE)

  target_include_directories(thirdparty_boost_any SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_any INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostForeach)
  set(library_root "${BOOST_ROOT}/libs/foreach")

  add_library(thirdparty_boost_foreach INTERFACE)

  target_include_directories(thirdparty_boost_foreach SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_foreach INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostMultiIndex)
  set(library_root "${BOOST_ROOT}/libs/multi_index")

  add_library(thirdparty_boost_multiindex INTERFACE)

  target_include_directories(thirdparty_boost_multiindex SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_multiindex INTERFACE
    thirdparty_boost_foreach
  )  
endfunction()

function(generateBoostPropertyTree)
  set(library_root "${BOOST_ROOT}/libs/property_tree")

  add_library(thirdparty_boost_propertytree INTERFACE)

  target_include_directories(thirdparty_boost_propertytree SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_propertytree INTERFACE
    thirdparty_boost_any
    thirdparty_boost_multiindex
  )  
endfunction()

function(generateBoostSpirit)
  set(library_root "${BOOST_ROOT}/libs/spirit")

  add_library(thirdparty_boost_spirit INTERFACE)

  target_include_directories(thirdparty_boost_spirit SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_spirit INTERFACE
    thirdparty_boost_optional
  )  
endfunction()

function(generateBoostAlgorithm)
  set(library_root "${BOOST_ROOT}/libs/algorithm")

  add_library(thirdparty_boost_algorithm INTERFACE)

  target_include_directories(thirdparty_boost_algorithm SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_algorithm INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostVariant)
  set(library_root "${BOOST_ROOT}/libs/variant")

  add_library(thirdparty_boost_variant INTERFACE)

  target_include_directories(thirdparty_boost_variant SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_variant INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostFormat)
  set(library_root "${BOOST_ROOT}/libs/format")

  add_library(thirdparty_boost_format INTERFACE)

  target_include_directories(thirdparty_boost_format SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_format INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostOptional)
  set(library_root "${BOOST_ROOT}/libs/optional")

  add_library(thirdparty_boost_optional INTERFACE)

  target_include_directories(thirdparty_boost_optional SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_optional INTERFACE
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostTypeIndex)
  set(library_root "${BOOST_ROOT}/libs/type_index")

  add_library(thirdparty_boost_typeindex INTERFACE)

  target_include_directories(thirdparty_boost_typeindex SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_typeindex INTERFACE
    thirdparty_boost_containerhash
  )  
endfunction()

function(generateBoostCoroutine2)
  set(library_root "${BOOST_ROOT}/libs/coroutine2")

  add_library(thirdparty_boost_coroutine2 INTERFACE)

  target_include_directories(thirdparty_boost_coroutine2 SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_coroutine2 INTERFACE
    thirdparty_boost_containerhash
  )  
endfunction()

function(generateBoostFunction)
  set(library_root "${BOOST_ROOT}/libs/function")

  add_library(thirdparty_boost_function INTERFACE)

  target_include_directories(thirdparty_boost_function SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_function INTERFACE
    thirdparty_boost_typeindex
    thirdparty_boost_bind
  )  
endfunction()

function(generateBoostException)
  set(library_root "${BOOST_ROOT}/libs/exception")

  add_library(thirdparty_boost_exception STATIC
    "${library_root}/src/clone_current_exception_non_intrusive.cpp"
  )

  target_include_directories(thirdparty_boost_exception SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_exception PUBLIC
    thirdparty_boost_config
  )  
endfunction()

function(generateBoostRatio)
  set(library_root "${BOOST_ROOT}/libs/ratio")

  add_library(thirdparty_boost_ratio INTERFACE)

  target_include_directories(thirdparty_boost_ratio SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_ratio INTERFACE
    thirdparty_boost_typetraits
    thirdparty_boost_core
    thirdparty_boost_integer
  )
endfunction()

function(generateBoostChrono)
  set(library_root "${BOOST_ROOT}/libs/chrono")

  add_library(thirdparty_boost_chrono STATIC
    "${library_root}/src/chrono.cpp"
    "${library_root}/src/process_cpu_clocks.cpp"
    "${library_root}/src/thread_clock.cpp"
  )

  target_include_directories(thirdparty_boost_chrono SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_chrono PUBLIC
    thirdparty_boost_predef
    thirdparty_boost_mpl
    thirdparty_boost_ratio
    thirdparty_boost_system
    thirdparty_boost_throwexception
    thirdparty_boost_utility
  )  
endfunction()

function(generateBoostMultiprecision)
  set(library_root "${BOOST_ROOT}/libs/multiprecision")

  add_library(thirdparty_boost_multiprecision INTERFACE)

  target_include_directories(thirdparty_boost_multiprecision SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_multiprecision INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostTokenizer)
  set(library_root "${BOOST_ROOT}/libs/tokenizer")

  add_library(thirdparty_boost_tokenizer INTERFACE)

  target_include_directories(thirdparty_boost_tokenizer SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_tokenizer INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostMath)
  set(library_root "${BOOST_ROOT}/libs/math")

  add_library(thirdparty_boost_math STATIC
    "${library_root}/src/tr1"
    "${library_root}/src/tr1/acosh.cpp"
    "${library_root}/src/tr1/acoshf.cpp"
    "${library_root}/src/tr1/acoshl.cpp"
    "${library_root}/src/tr1/asinh.cpp"
    "${library_root}/src/tr1/asinhf.cpp"
    "${library_root}/src/tr1/asinhl.cpp"
    "${library_root}/src/tr1/assoc_laguerre.cpp"
    "${library_root}/src/tr1/assoc_laguerref.cpp"
    "${library_root}/src/tr1/assoc_laguerrel.cpp"
    "${library_root}/src/tr1/assoc_legendre.cpp"
    "${library_root}/src/tr1/assoc_legendref.cpp"
    "${library_root}/src/tr1/assoc_legendrel.cpp"
    "${library_root}/src/tr1/atanh.cpp"
    "${library_root}/src/tr1/atanhf.cpp"
    "${library_root}/src/tr1/atanhl.cpp"
    "${library_root}/src/tr1/beta.cpp"
    "${library_root}/src/tr1/betaf.cpp"
    "${library_root}/src/tr1/betal.cpp"
    "${library_root}/src/tr1/c_policy.hpp"
    "${library_root}/src/tr1/cbrt.cpp"
    "${library_root}/src/tr1/cbrtf.cpp"
    "${library_root}/src/tr1/cbrtl.cpp"
    "${library_root}/src/tr1/comp_ellint_1.cpp"
    "${library_root}/src/tr1/comp_ellint_1f.cpp"
    "${library_root}/src/tr1/comp_ellint_1l.cpp"
    "${library_root}/src/tr1/comp_ellint_2.cpp"
    "${library_root}/src/tr1/comp_ellint_2f.cpp"
    "${library_root}/src/tr1/comp_ellint_2l.cpp"
    "${library_root}/src/tr1/comp_ellint_3.cpp"
    "${library_root}/src/tr1/comp_ellint_3f.cpp"
    "${library_root}/src/tr1/comp_ellint_3l.cpp"
    "${library_root}/src/tr1/copysign.cpp"
    "${library_root}/src/tr1/copysignf.cpp"
    "${library_root}/src/tr1/copysignl.cpp"
    "${library_root}/src/tr1/cyl_bessel_i.cpp"
    "${library_root}/src/tr1/cyl_bessel_if.cpp"
    "${library_root}/src/tr1/cyl_bessel_il.cpp"
    "${library_root}/src/tr1/cyl_bessel_j.cpp"
    "${library_root}/src/tr1/cyl_bessel_jf.cpp"
    "${library_root}/src/tr1/cyl_bessel_jl.cpp"
    "${library_root}/src/tr1/cyl_bessel_k.cpp"
    "${library_root}/src/tr1/cyl_bessel_kf.cpp"
    "${library_root}/src/tr1/cyl_bessel_kl.cpp"
    "${library_root}/src/tr1/cyl_neumann.cpp"
    "${library_root}/src/tr1/cyl_neumannf.cpp"
    "${library_root}/src/tr1/cyl_neumannl.cpp"
    "${library_root}/src/tr1/ellint_1.cpp"
    "${library_root}/src/tr1/ellint_1f.cpp"
    "${library_root}/src/tr1/ellint_1l.cpp"
    "${library_root}/src/tr1/ellint_2.cpp"
    "${library_root}/src/tr1/ellint_2f.cpp"
    "${library_root}/src/tr1/ellint_2l.cpp"
    "${library_root}/src/tr1/ellint_3.cpp"
    "${library_root}/src/tr1/ellint_3f.cpp"
    "${library_root}/src/tr1/ellint_3l.cpp"
    "${library_root}/src/tr1/erf.cpp"
    "${library_root}/src/tr1/erfc.cpp"
    "${library_root}/src/tr1/erfcf.cpp"
    "${library_root}/src/tr1/erfcl.cpp"
    "${library_root}/src/tr1/erff.cpp"
    "${library_root}/src/tr1/erfl.cpp"
    "${library_root}/src/tr1/expint.cpp"
    "${library_root}/src/tr1/expintf.cpp"
    "${library_root}/src/tr1/expintl.cpp"
    "${library_root}/src/tr1/expm1.cpp"
    "${library_root}/src/tr1/expm1f.cpp"
    "${library_root}/src/tr1/expm1l.cpp"
    "${library_root}/src/tr1/fmax.cpp"
    "${library_root}/src/tr1/fmaxf.cpp"
    "${library_root}/src/tr1/fmaxl.cpp"
    "${library_root}/src/tr1/fmin.cpp"
    "${library_root}/src/tr1/fminf.cpp"
    "${library_root}/src/tr1/fminl.cpp"
    "${library_root}/src/tr1/fpclassify.cpp"
    "${library_root}/src/tr1/fpclassifyf.cpp"
    "${library_root}/src/tr1/fpclassifyl.cpp"
    "${library_root}/src/tr1/hermite.cpp"
    "${library_root}/src/tr1/hermitef.cpp"
    "${library_root}/src/tr1/hermitel.cpp"
    "${library_root}/src/tr1/hypot.cpp"
    "${library_root}/src/tr1/hypotf.cpp"
    "${library_root}/src/tr1/hypotl.cpp"
    "${library_root}/src/tr1/laguerre.cpp"
    "${library_root}/src/tr1/laguerref.cpp"
    "${library_root}/src/tr1/laguerrel.cpp"
    "${library_root}/src/tr1/legendre.cpp"
    "${library_root}/src/tr1/legendref.cpp"
    "${library_root}/src/tr1/legendrel.cpp"
    "${library_root}/src/tr1/lgamma.cpp"
    "${library_root}/src/tr1/lgammaf.cpp"
    "${library_root}/src/tr1/lgammal.cpp"
    "${library_root}/src/tr1/llround.cpp"
    "${library_root}/src/tr1/llroundf.cpp"
    "${library_root}/src/tr1/llroundl.cpp"
    "${library_root}/src/tr1/log1p.cpp"
    "${library_root}/src/tr1/log1pf.cpp"
    "${library_root}/src/tr1/log1pl.cpp"
    "${library_root}/src/tr1/lround.cpp"
    "${library_root}/src/tr1/lroundf.cpp"
    "${library_root}/src/tr1/lroundl.cpp"
    "${library_root}/src/tr1/nextafter.cpp"
    "${library_root}/src/tr1/nextafterf.cpp"
    "${library_root}/src/tr1/nextafterl.cpp"
    "${library_root}/src/tr1/nexttoward.cpp"
    "${library_root}/src/tr1/nexttowardf.cpp"
    "${library_root}/src/tr1/nexttowardl.cpp"
    "${library_root}/src/tr1/pch.hpp"
    "${library_root}/src/tr1/riemann_zeta.cpp"
    "${library_root}/src/tr1/riemann_zetaf.cpp"
    "${library_root}/src/tr1/riemann_zetal.cpp"
    "${library_root}/src/tr1/round.cpp"
    "${library_root}/src/tr1/roundf.cpp"
    "${library_root}/src/tr1/roundl.cpp"
    "${library_root}/src/tr1/sph_bessel.cpp"
    "${library_root}/src/tr1/sph_besself.cpp"
    "${library_root}/src/tr1/sph_bessell.cpp"
    "${library_root}/src/tr1/sph_legendre.cpp"
    "${library_root}/src/tr1/sph_legendref.cpp"
    "${library_root}/src/tr1/sph_legendrel.cpp"
    "${library_root}/src/tr1/sph_neumann.cpp"
    "${library_root}/src/tr1/sph_neumannf.cpp"
    "${library_root}/src/tr1/sph_neumannl.cpp"
    "${library_root}/src/tr1/tgamma.cpp"
    "${library_root}/src/tr1/tgammaf.cpp"
    "${library_root}/src/tr1/tgammal.cpp"
    "${library_root}/src/tr1/trunc.cpp"
    "${library_root}/src/tr1/truncf.cpp"
    "${library_root}/src/tr1/truncl.cpp"
  )

  target_include_directories(thirdparty_boost_math SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_include_directories(thirdparty_boost_math PRIVATE
    "${library_root}/src/tr1"
  )

  target_link_libraries(thirdparty_boost_math PUBLIC
    thirdparty_boost_staticassert
    thirdparty_boost_predef
    thirdparty_boost_typetraits
    thirdparty_boost_mpl
    thirdparty_boost_throwexception
    thirdparty_boost_utility
    thirdparty_boost_array
    thirdparty_boost_lexicalcast
    thirdparty_boost_smartptr
    thirdparty_boost_multiprecision
    thirdparty_boost_io
    thirdparty_boost_tokenizer
  )  
endfunction()

function(generateBoostContainer)
  set(library_root "${BOOST_ROOT}/libs/container")

  add_library(thirdparty_boost_container STATIC
    "${library_root}/src/dlmalloc.cpp"
    "${library_root}/src/global_resource.cpp"
    "${library_root}/src/monotonic_buffer_resource.cpp"
    "${library_root}/src/pool_resource.cpp"
    "${library_root}/src/synchronized_pool_resource.cpp"
    "${library_root}/src/unsynchronized_pool_resource.cpp"
  )

  target_include_directories(thirdparty_boost_container SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_container PUBLIC
    thirdparty_boost_move
    thirdparty_boost_core
    thirdparty_boost_intrusive
  )  
endfunction()

function(generateBoostIntrusive)
  set(library_root "${BOOST_ROOT}/libs/intrusive")

  add_library(thirdparty_boost_intrusive INTERFACE)

  target_include_directories(thirdparty_boost_intrusive SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_intrusive INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostArray)
  set(library_root "${BOOST_ROOT}/libs/array")

  add_library(thirdparty_boost_array INTERFACE)

  target_include_directories(thirdparty_boost_array SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_array INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostNumeric)
  set(library_root "${BOOST_ROOT}/libs/numeric/conversion")

  add_library(thirdparty_boost_numericconversion INTERFACE)

  target_include_directories(thirdparty_boost_numericconversion SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_numericconversion INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostRange)
  set(library_root "${BOOST_ROOT}/libs/range")

  add_library(thirdparty_boost_range INTERFACE)

  target_include_directories(thirdparty_boost_range SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_range INTERFACE
    thirdparty_boost_iterator
    thirdparty_boost_conceptcheck
  )
endfunction()

function(generateBoostDateTime)
  set(library_root "${BOOST_ROOT}/libs/date_time")

  add_library(thirdparty_boost_datetime STATIC
    "${library_root}/src/gregorian/date_generators.cpp"
    "${library_root}/src/gregorian/greg_month.cpp"
    "${library_root}/src/gregorian/greg_names.hpp"
    "${library_root}/src/gregorian/greg_weekday.cpp"
    "${library_root}/src/gregorian/gregorian_types.cpp"
    "${library_root}/src/posix_time/posix_time_types.cpp"
  )

  target_include_directories(thirdparty_boost_datetime SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_datetime PUBLIC
    thirdparty_boost_throwexception
    thirdparty_boost_utility
    thirdparty_boost_mpl
    thirdparty_boost_typetraits
    thirdparty_boost_smartptr
    thirdparty_boost_lexicalcast
  )  
endfunction()

function(generateBoostConceptCheck)
  set(library_root "${BOOST_ROOT}/libs/concept_check")

  add_library(thirdparty_boost_conceptcheck INTERFACE)

  target_include_directories(thirdparty_boost_conceptcheck SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_conceptcheck INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostUtility)
  set(library_root "${BOOST_ROOT}/libs/utility")

  add_library(thirdparty_boost_utility INTERFACE)

  target_include_directories(thirdparty_boost_utility SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_utility INTERFACE
    thirdparty_boost_core
  )
endfunction()

function(generateBoostThrowException)
  set(library_root "${BOOST_ROOT}/libs/throw_exception")

  add_library(thirdparty_boost_throwexception INTERFACE)

  target_include_directories(thirdparty_boost_throwexception SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_throwexception INTERFACE
    thirdparty_boost_assert
  )
endfunction()

function(generateBoostMove)
  set(library_root "${BOOST_ROOT}/libs/move")

  add_library(thirdparty_boost_move INTERFACE)

  target_include_directories(thirdparty_boost_move SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_move INTERFACE
    thirdparty_boost_assert
    thirdparty_boost_staticassert
  )
endfunction()

function(generateBoostContainerHash)
  set(library_root "${BOOST_ROOT}/libs/container_hash")

  add_library(thirdparty_boost_containerhash INTERFACE)

  target_include_directories(thirdparty_boost_containerhash SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_containerhash INTERFACE
    thirdparty_boost_detail
  )
endfunction()

function(generateBoostIo)
  set(library_root "${BOOST_ROOT}/libs/io")

  add_library(thirdparty_boost_io INTERFACE)

  target_include_directories(thirdparty_boost_io SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_io INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostDetail)
  set(library_root "${BOOST_ROOT}/libs/detail")

  add_library(thirdparty_boost_detail INTERFACE)

  target_include_directories(thirdparty_boost_detail SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_detail INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostMpl)
  set(library_root "${BOOST_ROOT}/libs/mpl")

  add_library(thirdparty_boost_mpl INTERFACE)

  target_include_directories(thirdparty_boost_mpl SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_mpl INTERFACE
    thirdparty_boost_preprocessor
  )
endfunction()

function(generateBoostStaticAssert)
  set(library_root "${BOOST_ROOT}/libs/static_assert")

  add_library(thirdparty_boost_staticassert INTERFACE)

  target_include_directories(thirdparty_boost_staticassert SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_staticassert INTERFACE
  thirdparty_boost_config
)
endfunction()

function(generateBoostCore)
  set(library_root "${BOOST_ROOT}/libs/core")

  add_library(thirdparty_boost_core INTERFACE)

  target_include_directories(thirdparty_boost_core SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_core INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostTypeTraits)
  set(library_root "${BOOST_ROOT}/libs/type_traits")

  add_library(thirdparty_boost_typetraits INTERFACE)

  target_include_directories(thirdparty_boost_typetraits SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_typetraits INTERFACE
    thirdparty_boost_staticassert
    thirdparty_boost_assert
  )
endfunction()

function(generateBoostPreprocessor)
  set(library_root "${BOOST_ROOT}/libs/preprocessor")

  add_library(thirdparty_boost_preprocessor INTERFACE)

  target_include_directories(thirdparty_boost_preprocessor SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_preprocessor INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostBind)
  set(library_root "${BOOST_ROOT}/libs/bind")

  add_library(thirdparty_boost_bind INTERFACE)

  target_include_directories(thirdparty_boost_bind SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_bind INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostSmartPtr)
  set(library_root "${BOOST_ROOT}/libs/smart_ptr")

  add_library(thirdparty_boost_smartptr INTERFACE)

  target_include_directories(thirdparty_boost_smartptr SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_smartptr INTERFACE
    thirdparty_boost_predef
    thirdparty_boost_throwexception
    thirdparty_boost_move
  )
endfunction()

function(generateBoostAssert)
  set(library_root "${BOOST_ROOT}/libs/assert")

  add_library(thirdparty_boost_assert INTERFACE)

  target_include_directories(thirdparty_boost_assert SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_assert INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostIterator)
  set(library_root "${BOOST_ROOT}/libs/iterator")

  add_library(thirdparty_boost_iterator INTERFACE)

  target_include_directories(thirdparty_boost_iterator SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_iterator INTERFACE
    thirdparty_boost_mpl
    thirdparty_boost_assert
    thirdparty_boost_detail
  )
endfunction()

function(generateBoostConfig)
  set(library_root "${BOOST_ROOT}/libs/config")

  add_library(thirdparty_boost_config INTERFACE)

  target_include_directories(thirdparty_boost_config SYSTEM INTERFACE
    "${library_root}/include"
  )
endfunction()

function(generateBoostPredef)
  set(library_root "${BOOST_ROOT}/libs/predef")

  add_library(thirdparty_boost_predef INTERFACE)

  target_include_directories(thirdparty_boost_predef SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_predef INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostInteger)
  set(library_root "${BOOST_ROOT}/libs/integer")

  add_library(thirdparty_boost_integer INTERFACE)

  target_include_directories(thirdparty_boost_integer SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_integer INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostLexicalCast)
  set(library_root "${BOOST_ROOT}/libs/lexical_cast")

  add_library(thirdparty_boost_lexicalcast INTERFACE)

  target_include_directories(thirdparty_boost_lexicalcast SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_lexicalcast INTERFACE
    thirdparty_boost_range
    thirdparty_boost_numericconversion
    thirdparty_boost_integer
    thirdparty_boost_array
    thirdparty_boost_container
    thirdparty_boost_math
  )
endfunction()

function(generateBoostContext)
  set(library_root "${BOOST_ROOT}/libs/context")

  add_library(thirdparty_boost_context STATIC
    "${library_root}/src/execution_context.cpp"
  )

  if(DEFINED PLATFORM_POSIX)
    target_sources(thirdparty_boost_context PRIVATE
      "${library_root}/src/posix/stack_traits.cpp"
    )

  elseif(DEFINED PLATFORM_WINDOWS)
    target_sources(thirdparty_boost_context PRIVATE
      "${library_root}/src/windows/stack_traits.cpp"
    )
  endif()

  target_include_directories(thirdparty_boost_context SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_context PUBLIC
    thirdparty_boost_config
    thirdparty_boost_assert
    thirdparty_boost_smartptr
  )  
endfunction()

function(generateBoostCoroutine)
  set(library_root "${BOOST_ROOT}/libs/coroutine")

  add_library(thirdparty_boost_coroutine STATIC
    "${library_root}/src/exceptions.cpp"
    "${library_root}/src/detail/coroutine_context.cpp"
  )

  if(DEFINED PLATFORM_POSIX)
    target_sources(thirdparty_boost_coroutine PRIVATE
      "${library_root}/src/posix/stack_traits.cpp"
    )

  elseif(DEFINED PLATFORM_WINDOWS)
    target_sources(thirdparty_boost_coroutine PRIVATE
      "${library_root}/src/windows/stack_traits.cpp"
    )
  endif()

  # TODO: the asm/ files!

  target_include_directories(thirdparty_boost_coroutine SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_coroutine PUBLIC
    thirdparty_boost_core
    thirdparty_boost_system
    thirdparty_boost_typetraits
    thirdparty_boost_context
    thirdparty_boost_thread
  )  
endfunction()

function(generateBoostFilesystem)
  set(library_root "${BOOST_ROOT}/libs/filesystem")

  add_library(thirdparty_boost_filesystem STATIC
    "${library_root}/src/codecvt_error_category.cpp"
    "${library_root}/src/operations.cpp"
    "${library_root}/src/path.cpp"
    "${library_root}/src/path_traits.cpp"
    "${library_root}/src/portability.cpp"
    "${library_root}/src/unique_path.cpp"
    "${library_root}/src/utf8_codecvt_facet.cpp"
  )

  if(DEFINED PLATFORM_WINDOWS)
    target_sources(thirdparty_boost_filesystem PRIVATE
      "${library_root}/src/windows_file_codecvt.cpp"
    )
  endif()

  target_include_directories(thirdparty_boost_filesystem SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_filesystem PUBLIC
    thirdparty_boost_system
    thirdparty_boost_typetraits
    thirdparty_boost_core
    thirdparty_boost_iterator
    thirdparty_boost_io
    thirdparty_boost_containerhash
    thirdparty_boost_smartptr
  )
endfunction()

function(generateBoostRegex)
  set(library_root "${BOOST_ROOT}/libs/regex")

  add_library(thirdparty_boost_regex STATIC
    "${library_root}/src/cpp_regex_traits.cpp"
    "${library_root}/src/cregex.cpp"
    "${library_root}/src/c_regex_traits.cpp"
    "${library_root}/src/fileiter.cpp"
    "${library_root}/src/icu.cpp"
    "${library_root}/src/instances.cpp"
    "${library_root}/src/internals.hpp"
    "${library_root}/src/posix_api.cpp"
    "${library_root}/src/regex.cpp"
    "${library_root}/src/regex_debug.cpp"
    "${library_root}/src/regex_raw_buffer.cpp"
    "${library_root}/src/regex_traits_defaults.cpp"
    "${library_root}/src/static_mutex.cpp"
    "${library_root}/src/usinstances.cpp"
    "${library_root}/src/w32_regex_traits.cpp"
    "${library_root}/src/wc_regex_traits.cpp"
    "${library_root}/src/wide_posix_api.cpp"
    "${library_root}/src/winstances.cpp"
  )

  target_include_directories(thirdparty_boost_regex SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_regex PUBLIC
    thirdparty_boost_predef
    thirdparty_boost_assert
    thirdparty_boost_throwexception
    thirdparty_boost_smartptr
    thirdparty_boost_core
    thirdparty_boost_mpl
    thirdparty_boost_typetraits
    thirdparty_boost_integer
    thirdparty_boost_containerhash
  )
endfunction()

function(generateBoostTuple)
  set(library_root "${BOOST_ROOT}/libs/tuple")

  add_library(thirdparty_boost_tuple INTERFACE)

  target_include_directories(thirdparty_boost_tuple SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_tuple INTERFACE
    thirdparty_boost_config
  )
endfunction()

function(generateBoostAtomic)
  set(library_root "${BOOST_ROOT}/libs/atomic")

  add_library(thirdparty_boost_atomic STATIC
    "${library_root}/src/lockpool.cpp"
  )

  target_include_directories(thirdparty_boost_atomic SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_atomic PUBLIC
    thirdparty_boost_assert
  )
endfunction()

function(generateBoostThread)
  set(library_root "${BOOST_ROOT}/libs/thread")

  add_library(thirdparty_boost_thread STATIC
    "${library_root}/src/future.cpp"
    "${library_root}/src/tss_null.cpp"
  )

  if(DEFINED PLATFORM_POSIX)
    target_sources(thirdparty_boost_thread PRIVATE
      "${library_root}/src/pthread/once.cpp"
      "${library_root}/src/pthread/once_atomic.cpp"
      "${library_root}/src/pthread/thread.cpp"
    )

  elseif(DEFINED PLATFORM_WINDOWS)
    target_sources(thirdparty_boost_thread PRIVATE
      "${library_root}/src/win32/thread.cpp"
      "${library_root}/src/win32/thread_primitives.cpp"
      "${library_root}/src/win32/tss_dll.cpp"
      "${library_root}/src/win32/tss_pe.cpp"
    )
  endif()

  target_include_directories(thirdparty_boost_thread SYSTEM PUBLIC
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_thread PUBLIC
    thirdparty_boost_core
    thirdparty_boost_system
    thirdparty_boost_typetraits
    thirdparty_boost_move
    thirdparty_boost_mpl
    thirdparty_boost_bind
    thirdparty_boost_atomic
    thirdparty_boost_datetime
    thirdparty_boost_chrono
    thirdparty_boost_containerhash
    thirdparty_boost_tuple
    thirdparty_boost_exception
    thirdparty_boost_optional
    thirdparty_boost_function
    thirdparty_boost_typeindex
    thirdparty_boost_algorithm
  )
endfunction()

function(generateBoostSystem)
  set(library_root "${BOOST_ROOT}/libs/system")

  add_library(thirdparty_boost_system INTERFACE)

  target_include_directories(thirdparty_boost_system SYSTEM INTERFACE
    "${library_root}/include"
  )

  target_link_libraries(thirdparty_boost_system INTERFACE
    thirdparty_boost_config
  )
endfunction()

boostMain()
