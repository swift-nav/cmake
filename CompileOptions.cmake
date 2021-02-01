include(CheckCCompilerFlag)
include(CheckCXXCompilerFlag)

function(swift_set_compile_options)
    set(argOption "WARNING" "EXCEPTIONS" "RTTI")
    set(argSingle "")
    set(argMulti "ADD" "REMOVE")

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

    list(APPEND all_flags ${x_ADD})

    unset(final_flags)

    get_property(enabled_languages GLOBAL PROPERTY ENABLED_LANGUAGES)
    list(FIND enabled_languages "C" c_enabled)
    list(FIND enabled_languages "CXX" cxx_enabled)

    foreach(flag ${all_flags})
      string(REPLACE "-" "_" sanitised_flag ${flag})
      string(TOUPPER sanitised_flag ${sanitised_flag})

      set(c_supported C_FLAG_${sanitised_flag})
      set(cxx_supported CXX_FLAG_${sanitised_flag})

      if(${c_enabled} GREATER -1)
        check_c_compiler_flag(${flag} ${c_supported})
        if(${${c_supported}})
          list(APPEND final_flags $<$<COMPILE_LANGUAGE:C>:${flag}>)
        endif()
      endif()

      if (${cxx_enabled} GREATER -1)
        check_cxx_compiler_flag(${flag} ${cxx_supported})
        if(${${cxx_supported}})
          list(APPEND final_flags $<$<COMPILE_LANGUAGE:CXX>:${flag}>)
        endif()
      endif()
    endforeach()

    foreach(target ${targets})
      target_compile_options(${target} PRIVATE ${final_flags})
    endforeach()

endfunction()

