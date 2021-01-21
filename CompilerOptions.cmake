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
    -Wextra
    -Wno-unused-value
    -Wcast-align
    -Wcast-qual
    -Wchar-subscripts
    -Wcomment
    -Wconversion
    -Wdisabled-optimization
    -Wfloat-equal
    -Wformat
    -Wformat-security
    -Wformat-y2k
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
    $<$<COMPILE_LANGUAGE:CXX>:-fno-exceptions>
    $<$<COMPILE_LANGUAGE:CXX>:-fno-rtti>
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
    )
  endif()
endfunction()

function(_gnu_warnings target)
endfunction()

