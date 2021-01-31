include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

function(swift_set_compile_options)
    set(argOption "WARNING" "EXCEPTIONS" "RTTI")
    set(argSingle "")
    set(argMulti "EXTRA" "REMOVE")

    cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
    set(targets ${x_UNPARSED_ARGUMENTS})

    if (MSVC)
      return()
    endif()

    if (DEFINED SWIFT_COMPILER_WARNING_ARE_ERROR)
      if (SWIFT_COMPILER_WARNING_ARE_ERROR)
        set(all_flags -Werror)
      else()
        set(all_flags -Wno-error)
      endif()
    else()
      if (NOT x_WARNING)
        set(all_flags -Werror)
      endif()
    endif()

    # The following flags are supported by all version of gcc and clang
    # and can safely be specified without any extra checks
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
        -fno-strict-aliasing
    )

    if(x_REMOVE)
      list(REMOVE_ITEM all_flags ${x_REMOVE})
    endif()

    if(x_EXCEPTIONS)
      list(APPEND all_flags -fexceptions)
    else()
      list(APPEND all_flags -fno-exceptions)
    endif()

    if(x_RTTI)
      list(APPEND all_flags -frtti)
    else()
      list(APPEND all_flags -fno-rtti)
    endif()

    list(APPEND all_flags ${x_EXTRA})

    foreach(flag ${x_EXTRA})
      string(REPLACE "-" "_" sanitised_flag ${flag})
      string(TOUPPER sanitised_flag ${sanitised_flag})

      set(c_supported C_FLAG_${sanitised_flag})
      set(cxx_supported CXX_FLAG_${sanitised_flag})

      check_c_compiler_flag(${flag} ${c_supported})
      if(${${c_supported}})
        target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:C>:${flag}>)
      endif()

      check_cxx_compiler_flag(${flag} ${cxx_supported})
      if(${${cxx_supported}))
        target_compile_options(${target} PRIVATE $<$<COMPILE_LANGUAGE:CXX>:${flag}>)
      endif()
    endforeach()
endfunction()

