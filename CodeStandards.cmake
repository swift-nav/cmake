#
# Offers a simple function to set a number of targets to follow the company
# wide C/C++ code standards.
#
#   swift_target_code_standards(target1 target2...
#     [C_STANDARD <C standard>]
#     [CXX_STANDARD <C++ standard>]
#     [EXCEPTIONS]
#     [RTTI]
#     [WARNING]
#   )
#
# Options:
#
#   C_STANDARD [default=99]
#     C language standard to follow, current support values are 90, 99, and 11
#     (see: https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html).
#
#   CXX_STANDARD [default=14]
#     C++ language standard to follow, current supported values are 98, 11, 14,
#     17, and 20 (see: https://cmake.org/cmake/help/latest/prop_tgt/CXX_STANDARD.html).
#
#   EXCEPTION
#     By default exceptions are disabled, adding this option enables exceptions
#     to be thrown inside the target.
#
#   RTTI
#     By default RTTI (run-time type information) is disabled, adding this
#     option enables RTTI to be used within target.
#
#   UNWIND
#     By default stack unwinding is disabled, adding this option enables stack
#     unwinding in the target.
#
#   WARNING
#     By default all compiler warnings are treated as errors, adding this
#     option treats all warnings as just warnings.
#
# Global Variables
#
#   SWIFT_COMPILER_WARNING_ARE_ERROR [bool]
#     If the variable is present, this option overrules the company standard
#     practice as well as function options. A value of true would make all
#     warnings into error, a value of false would leave warnings as just
#     warnings.
#
# NOTE
#
#   This module offers the same functionality as swift_set_language_standards
#   does, new cmake code should be using this module over the other as it offers
#   more than just language standards.
#

function(swift_target_code_standards)
  set(argOption EXCEPTION RTTI UNWIND WARNING)
  set(argSingle C CXX)
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

  _common_options()
  _clang_options()
  _gnu_options()

endfunction()

function (_common_options)
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

  if (NOT x_EXCEPTION)
    target_compile_options(${TARGETS} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>)
  endif()

  if (NOT x_RTTI)
    target_compile_options(${TARGETS} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>)
  endif()

  if (NOT x_UNWIND)
    target_compile_options(${TARGETS}
      PRIVATE
        -fno-asynchronous-unwind-tables
        -fno-unwind-tables
    )
  endif()

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

function(_clang_options)
  if (CMAKE_C_COMPILER_ID MATCHES "Clang")
    target_compile_options(${TARGETS}
      PRIVATE
        -Wimplicit-fallthrough
        -Wno-error=typedef-redefinition
    )
  endif()
endfunction()

function(_gnu_options)
endfunction()
