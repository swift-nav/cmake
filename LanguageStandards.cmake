#
# Offers a simple function to set a number of targets to follow the company
# wide C/C++ standards. One can bypass some of these standards through the
# following options:
#
# Single Value Options:
#
#  C
#    C language standard to follow, current support values are 90, 99, and 11
#    (see: https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html)
#
#  CXX
#    C++ language standard to follow, current supported values are 98, 11, 14,
#    17, and 20 (see: https://cmake.org/cmake/help/latest/prop_tgt/CXX_STANDARD.html)
#
#  WARNING
#    By default all compiler warnings are treated as errors, adding this
#    option treats all warnings as just warnings.
#
# Global Variable:
#
#  SWIFT_COMPILER_WARNING_ARE_ERROR
#    If the variable is present, this option overrules the company standard
#    practice as well as function options. A value of true would make all
#    warnings into error, a value of false would leave warnings as just
#    warnings.
#
# Usage: set a target to conform to company standard
#
#   add_executable(target_name main.cpp)
#   swift_set_language_standards(target_name)
#
# Usage: specify your own standards (C++17 and C98) on multiple targets
#
#   add_library(library_target file1.c file2.cc)
#   add_executable(executable_target main.cpp)
#   target_link_libraries(executable_target PRIVATE library_target)
#
#   swift_set_language_standards(executable_target library_target
#     C 99
#     CXX 17
#   )
#

function(swift_set_language_standards)
    set(argOption "WARNING")
    set(argSingle "C" "CXX")
    set(argMulti "")

    cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
    set(TARGETS ${x_UNPARSED_ARGUMENTS})

    if(NOT x_C)
        set(x_C 99)
    endif()

    if(NOT x_CXX)
        set(x_CXX 14)
    endif()

    set_target_properties(${TARGETS}
        PROPERTIES
            C_STANDARD ${x_C}
            C_STANDARD_REQUIRED ON
            C_EXTENSIONS ON
            CXX_STANDARD ${x_CXX}
            CXX_STANDARD_REQUIRED ON
            CXX_EXTENSIONS OFF
    )

    _common_clang_gnu_warnings()
    _clang_warnings()
    _gnu_warnings()
endfunction()

function (_common_clang_gnu_warnings)
  target_compile_options(${TARGETS}
    PRIVATE
      $<$<COMPILE_LANGUAGE:C>:-Wno-strict-prototypes>
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
      -Wformat-nonliteral
      -Wformat-security
      -Wformat-y2k
      -Wimport
      -Winit-self
      -Winvalid-pch
      -Wmissing-braces
      -Wmissing-field-initializers
      -Wmissing-format-attribute
      -Wmissing-include-dirs
      -Wmissing-noreturn
      -Wno-unused-value
      -Wparentheses
      -Wpointer-arith
      -Wredundant-decls
      -Wreturn-type
      -Wsequence-point
      -Wshadow
      -Wsign-compare
      -Wstack-protector
      -Wstrict-aliasing
      -Wstrict-aliasing=2
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

  if (DEFINED SWIFT_COMPILER_WARNING_ARE_ERROR)
    if (SWIFT_COMPILER_WARNING_ARE_ERROR)
      target_compile_options(${TARGETS} PRIVATE -Werror)
    else()
      target_compile_options(${TARGETS} PRIVATE -Wno-error)
    endif()
  else()
    if (NOT x_WARNING)
      target_compile_options(${TARGETS} PRIVATE -Werror)
    endif()
  endif()
endfunction()

function(_clang_warnings)
  if (CMAKE_C_COMPILER_ID MATCHES "Clang")
    target_compile_options(${TARGETS}
      PRIVATE
        -Wimplicit-fallthrough
        -Wno-error=typedef-redefinition
    )
  endif()
endfunction()

function(_gnu_warnings)
endfunction()