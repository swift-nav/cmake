#
# ADD DOCUMENTATION
#

option(PROFILING "Builds targets with profiling instrumentation. Currently only works with GCC Compilers" OFF)

if (PROFILING)
  if(NOT CMAKE_COMPILER_IS_GNUCXX)
    message(FATAL_ERROR "Profiling support is currently only available for GCC compiler")
  endif()
endif()

function(target_add_profiling target)
  if (NOT PROFILING)
    return()
  endif()

  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
    return()
  endif()

  target_compile_options(${target} PRIVATE -pg)
  target_link_libraries(${target} PRIVATE -pg)
endfunction()

function(swift_add_profiling target)
  set(argOption GENERATE_REPORT)
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  if (NOT PROFILING)
    return()
  endif()

  target_add_profiling(${target})

  get_target_property(target_type ${target} TYPE)

  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling")
  endif()

  if (CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  find_package(GProf)

  if (NOT GProf_FOUND)
    message(WARNING "GProf program is required to generate profiling report")
    return()
  endif()

  set(target_name ${target}-profiling)
  if (x_NAME)
    set(target_name ${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${working_directory})
  endif()

  unset(post_commands)
  if (x_GENERATE_REPORT)
    list(APPEND post_commands COMMAND find ${working_directory}/${target_name} -regex ".+/gmon\\.[0-9]+$" -exec sh -c "${GProf_EXECUTABLE} $<TARGET_FILE:${target}> $0 > $0.txt" {} +)
  endif()

  add_custom_target(${target_name}
    COMMENT "Profiling report is running for \"${target}\" (output: \"${working_directory}/${target_name}/${report_file}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E chdir ${working_directory}/${target_name} ${CMAKE_COMMAND} -E env GMON_OUT_PREFIX=gmon $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    ${post_commands}
    DEPENDS ${target}
    VERBATIM
  )

  if (NOT TARGET do-all-profiling)
    add_custom_target(do-all-profiling)
  endif()
  add_dependencies(do-all-profiling ${target_name})
endfunction()