#
# Copyright (C) 2021 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

#
# Set a common set of compiler options and warning flags
#
# Call swift_set_compile_options() for any target to set
# the Swift default set of compiler options. This includes
# - exceptions disabled
# - rtti disabled
# - strict aliasing disabled
# - Warnings as errors (-Werror)
# - Extensive set of enabled warnings
#
# Exceptions and/or RTTI can be selectively enabled for a 
# target be passing EXCEPTIONS and/or RTTI as a parameter, eg 
#
#    swift_set_compile_options(sample-target EXCEPTIONS RTTI)
#
# will enable exceptions and rtti for sample-target only
#
# Warning flags can be removed from the default set by passing
# REMOVE followed by a list of warning flags, eg 
#
#    swift_set_compile_options(sample-target REMOVE -Wconversion)
#
# will prevent -Wconversion from being passed to the compiler 
# for sample-target only 
#
# Similarly extra options can be given by passing ADD followed 
# by a list of warning flags (or other compiler options), eg 
#
#    swift_set_compile_options(sample-target ADD -Wformat=2)
#
# will pass -Wformat=2 to the compiler for sample-target only 
#
# By default -Werror is set, but this can be prevented by passing 
# WARNING as a parameter, eg 
#
#    swift_set_compile_options(sample-target WARNING)
#
# will disable warnings-as-errors for sample-target only 
#
# All flags will be checked for suitability with the in-use
# compilers before being selected. This is important since 
# Swift code tends to be compiled with a wide variety of 
# compilers which may not support the same set of flags and 
# options. Therefore, it should be preferred to use this 
# function to set compiler flags and options rather than 
# target_compile_options()
#

include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

function(swift_set_compile_options)
    set(argOption "WARNING" "NO_EXCEPTIONS" "EXCEPTIONS" "NO_RTTI" "RTTI")
    set(argSingle "")
    set(argMulti "ADD" "REMOVE")

    unset(x_EXCEPTIONS)
    unset(x_NO_EXCEPTIONS)
    unset(x_RTTI)
    unset(x_NO_RTTI)
    unset(x_WARNING)
    unset(x_ADD)
    unset(x_REMOVE)

    cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
    set(targets ${x_UNPARSED_ARGUMENTS})

    if (x_RTTI AND x_NO_RTTI)
      message(FATAL_ERROR "RTTI and NO_RTTI can't be used together")
    endif()

    if (x_EXCEPTIONS AND x_NO_EXCEPTIONS)
      message(FATAL_ERROR "EXCEPTIONS and NO_EXCEPTIONS can't be used together")
    endif()

    if (MSVC)
      return()
    endif()

    foreach(flag ${x_ADD} ${x_REMOVE})
      if(${flag} STREQUAL "-fexceptions")
        message(FATAL_ERROR "Do not specify -fexceptions directly, use EXCEPTIONS instead")
      endif()
      if(${flag} STREQUAL "-fno-exceptions")
        message(FATAL_ERROR "Do not specify -fno-exceptions directly, use NO_EXCEPTIONS instead")
      endif()
      if(${flag} STREQUAL "-frtti")
        message(FATAL_ERROR "Do not specify -frtti directly, use RTTI instead")
      endif()
      if(${flag} STREQUAL "-fno-rtti")
        message(FATAL_ERROR "Do not specify -fno-rtti directly, use NO_RTTI instead")
      endif()
      if(${flag} STREQUAL "-Werror")
        message(FATAL_ERROR "Do not specify -Werror directly, use WARNING to disable -Werror")
      endif()
      if(${flag} STREQUAL "-Wno-error")
        message(FATAL_ERROR "Do not specify -Wno-error directly, use WARNING to disable -Werror")
      endif()
    endforeach()

    if (DEFINED SWIFT_COMPILER_WARNING_ARE_ERROR)
      if (SWIFT_COMPILER_WARNING_ARE_ERROR)
        set(all_flags -Werror -Wno-error=deprecated-declarations)
      else()
        set(all_flags -Wno-error)
      endif()
    else()
      if (NOT x_WARNING)
        set(all_flags -Werror -Wno-error=deprecated-declarations)
      endif()
    endif()

    list(APPEND all_flags
        -Wall
        -Wcast-align
        -Wcast-qual
        -Wchar-subscripts
        -Wcomment
        -Wconversion
        -Wdisabled-optimization
        -Wextra
        -Wfloat-equal
        -Wformat
        -Wformat-security
        -Wformat-y2k
        -Wimplicit-fallthrough
        -Wimport
        -Winit-self
        -Winvalid-pch
        -Wmissing-braces
        -Wmissing-field-initializers
        -Wmissing-include-dirs
        -Wparentheses
        -Wpointer-arith
        -Wredundant-decls
        -Wreturn-type
        -Wsequence-point
        -Wshadow
        -Wsign-compare
        -Wstack-protector
        -Wswitch
        -Wswitch-default
        -Wswitch-enum
        -Wtrigraphs
        -Wuninitialized
        -Wunknown-pragmas
        -Wunreachable-code
        -Wunused
        -Wunused-function
        -Wunused-label
        -Wunused-parameter
        -Wunused-value
        -Wunused-variable
        -Wvolatile-register-var
        -Wwrite-strings
    )

    if(x_REMOVE)
      foreach(flag ${x_REMOVE})
        list(FIND all_flags ${flag} found)
        if(found EQUAL -1)
          message(FATAL_ERROR "Compiler flag '${flag}' specified for removal is not part of the set of common compiler flags")
        endif()
      endforeach()
      list(REMOVE_ITEM all_flags ${x_REMOVE})
    endif()

    list(APPEND all_flags ${x_ADD})

    unset(final_flags)

    get_property(enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
    list(FIND enabled_languages "C" c_enabled)
    list(FIND enabled_languages "CXX" cxx_enabled)

    foreach(flag ${all_flags})
      string(TOUPPER ${flag} sanitised_flag)
      string(REPLACE "+" "X" sanitised_flag ${sanitised_flag})
      string(REGEX REPLACE "[^A-Za-z_0-9]" "_" sanitised_flag ${sanitised_flag})

      set(c_supported HAVE_C_FLAG_${sanitised_flag})
      string(REGEX REPLACE "_+" "_" c_supported ${c_supported})
      set(cxx_supported HAVE_CXX_FLAG_${sanitised_flag})
      string(REGEX REPLACE "_+" "_" cxx_supported ${cxx_supported})

      if(${c_enabled} GREATER -1)
        check_c_compiler_flag("-Werror ${flag}" ${c_supported})
        if(${${c_supported}})
          list(APPEND final_flags $<$<COMPILE_LANGUAGE:C>:${flag}>)
        endif()
      endif()

      if (${cxx_enabled} GREATER -1)
        check_cxx_compiler_flag("-Werror ${flag}" ${cxx_supported})
        if(${${cxx_supported}})
          list(APPEND final_flags $<$<COMPILE_LANGUAGE:CXX>:${flag}>)
        endif()
      endif()
    endforeach()

    foreach(target ${targets})
      if(cxx_enabled)
        if(x_EXCEPTIONS)
          target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-fexceptions>)
        else()
          target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>)
        endif()

        if(x_RTTI)
          target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-frtti>)
        else()
          target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>)
        endif()
      endif()

      target_compile_options(${target} PRIVATE ${final_flags})
    endforeach()

endfunction()

