include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

function(swift_set_compile_options)
    set(argOption "WARNING")
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
        -Wextra
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
        -fno-strict-aliasing
    )

    if(x_REMOVE)
      list(REMOVE_ITEM all_flags ${x_REMOVE})
    endif()

    # -Wimplicit-fallthrough only works on clang and later gcc versions
    list(INSERT x_EXTRA 0 -Wimplicit-fallthrough)

    # add in any extra flags specified by the caller.
    foreach(flag ${x_EXTRA})
      string(REPLACE "-" "_" supported ${flag})
      check_c_compiler_flag(${flag} ${supported})
      if(${${supported}})
        list(APPEND all_flags $<$<COMPILE_LANGUAGE:C>:${flag}>)
      endif()
      check_cxx_compiler_flag(${flag} ${supported})
      if(${${supported}})
        list(APPEND all_flags $<$<COMPILE_LANGUAGE:CXX>:${flag}>)
      endif()
    endforeach()

    # finally set the private compile options for each target
    foreach(target IN LISTS targets)
      target_compile_options(${target} PRIVATE ${all_flags})
    endforeach()
endfunction()

