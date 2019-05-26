function(swift_setup_clang_format)
  set(argOption "")
  set(argSingle "SCRIPT")
  set(argMulti "CLANG_FORMAT_NAMES")

  cmake_parse_arguments(x "${argOptions}" "${argSingle}" "${argMulti}" ${ARGN})

  set(top_level_project OFF)
  if(${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # This is the top level project, ie the CMakeLists.txt which cmake was run
    # on directly, not a submodule/subproject. We can do some special things now.
    # The option to enable clang formatting will be enabled by default only for
    # top level projects. Also the top level project will create an alias target
    # clang-format-all against the project specific target
    set(top_level_project ON)
  endif()

  message(STATUS "top_level_project ${top_level_project}")

  option(${PROJECT_NAME}_ENABLE_CLANG_FORMAT "Enable auto-formatting of code using clang-format" ${top_level_project})

  if(NOT ${PROJECT_NAME}_ENABLE_CLANG_FORMAT)
    # Explicitly disabled
    message(STATUS "${PROJECT_NAME} clang-format support is DISABLED")
    return()
  endif()

  if(NOT x_CLANG_FORMAT_NAMES)
    set(x_CLANG_FORMAT_NAMES 
        clang-format60 clang-format-6.0
        clang-format40 clang-format-4.0
        clang-format39 clang-format-3.9
        clang-format38 clang-format-3.8
        clang-format37 clang-format-3.7
        clang-format36 clang-format-3.6
        clang-format35 clang-format-3.5
        clang-format34 clang-format-3.4
        clang-format
       )
  endif()
  find_program(CLANG_FORMAT NAMES ${x_CLANG_FORMAT_NAMES})

  if("${CLANG_FORMAT}" STREQUAL "CLANG_FORMAT-NOTFOUND")
    message(warning "Could not find appropriate clang-format, target disabled")
    return()
  else()
    message(STATUS "Using ${CLANG_FORMAT}")
    set(${PROJECT_NAME}_CLANG_FORMAT ${CLANG_FORMAT} CACHE STRING "Absolute path to clang-format for ${PROJECT_NAME}")
  endif()

  set(target clang-format-${PROJECT_NAME})

  if(x_SCRIPT)
    set(custom_scripts ${x_SCRIPT})
  else()
    set(custom_scripts "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-format.sh" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-format.bash")
  endif()

  foreach(script ${x_SCRIPTS})
    if(EXISTS ${script})
      message(STATUS "Initialising clang format target for ${PROJECT_NAME} using existing script in ${script}")
      add_custom_target(${target}
          COMMAND "${script}"
          WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
          )
      return()
    endif()
  endforeach()

  # Don't quote the command here, we need it to come out as a cmake list to be passed to
  # add_custom_target correctly
  set(format_all_command git ls-files '*.[ch]' '*.cpp' '*.cc' '*.hpp' | xargs ${${PROJECT_NAME}_CLANG_FORMAT} -i)

  add_custom_target(${target}
      COMMAND ${format_all_command}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )

  if(${top_level_project})
    # Cmake doesn't support aliasing non-library targets, so we have to just redefine the target entirely
    add_custom_target(clang-format-all
        COMMAND ${format_all_command}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
  endif()
endfunction()
