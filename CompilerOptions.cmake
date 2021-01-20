function(swift_set_compiler_options)
    set(argOption "LENIENT" "WARNING")
    set(argSingle "")
    set(argMulti "")

    cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
    set(targets ${x_UNPARSED_ARGUMENTS})

    foreach(target IN LISTS targets)
  target_compile_options(${target}
    PRIVATE
      -Wall
      -Wcast-align
      -Wchar-subscripts
      -Wcomment
      -Wdisabled-optimization
      -Wformat
      -Wformat-security
      -Wformat-y2k
      -Wimport
      -Winit-self
      -Winvalid-pch
      -Wmissing-braces
      -Wmissing-field-initializers
      -Wno-unused-value
      -Wparentheses
      -Wpointer-arith
      -Wreturn-type
      -Wsequence-point
      -Wsign-compare
      -Wstack-protector
      -Wswitch
      -Wtrigraphs
      -Wuninitialized
      -Wunknown-pragmas
      -Wunused
      -Wunused-function
      -Wunused-label
      -Wunused-value
      -Wunused-variable
      -Wvolatile-register-var
      -Wwrite-strings
        -Wcast-qual
        -Wextra
        -Wfloat-equal
        -Wformat-nonliteral
        -Wformat=2
        -Wmissing-format-attribute
        -Wmissing-include-dirs
        -Wmissing-noreturn
        -Wredundant-decls
        -Wshadow
        -Wstrict-aliasing
        -Wstrict-aliasing=2
        -Wswitch-default
        -Wswitch-enum
        -Wunreachable-code
        -Wunused-parameter
  )

  if (DEFINED SWIFT_COMPILER_WARNING_ARE_ERROR)
    if (SWIFT_COMPILER_WARNING_ARE_ERROR)
      target_compile_options(${target} PRIVATE -Werror)
    else()
      target_compile_options(${target} PRIVATE -Wno-error)
    endif()
  else()
    if (NOT x_WARNING)
      target_compile_options(${target} PRIVATE -Werror)
    endif()
  endif()

      if(CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        _clang_warnings(${target})
      elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        _gnu_warnings(${target})
      endif()
    endforeach()
endfunction()

function(_clang_warnings target)
  if (CMAKE_C_COMPILER_ID MATCHES "Clang")
    target_compile_options(${target}
      PRIVATE
        -Wimplicit-fallthrough
        -Wno-error=typedef-redefinition
    )
  endif()
endfunction()

function(_gnu_warnings target)
endfunction()

