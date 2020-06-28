#
# OVERVIEW
#
# Bloaty is a static memory profiling tool which measures the size utilization
# of a target binary and outputs the result to a file.
#
# USAGE
#
#   swift_add_bloaty(<target>
#     [OPTIONS]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with bloaty applied.
#
# BLOATY OPTIONS
#
#   * SEGMENTS:     Outputs what the run-time loader uses to determine what
#                   parts of the binary needs to be loaded/mapped into memory.
#   * SECTIONS:     Outputs the binary in finer details structured in different sections.
#   * SYMBOLS:      Outputs individual functions or variables.
#   * COMPILEUNITS: Outputs what compile unit (and corresponding source file)
#                   each bit of the binary came from.
#   * SORT:
#       vm   - Sort the vm size column from largest to smallest and tells you
#              how much space the binary will take when loaded into memory.
#       file - Sort the file size column from largest to smallest and tells you
#              how much space the binary is taking on disk.
#       both - Default, sorts by max(vm, file).
#
# WORKING_DIRECTORY
# This variable enables a user to change the output directory for the tools
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}`. Setting this option for
# target `starling-binary` to `/tmp`, outputs the results into
# `/tmp/bloaty-reports/
#
# NOTE
# * A cmake option is available to control whether targets should be built, 
# with the name ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING.
#
# Running
#
# cmake -D<project>_ENABLE_MEMORY_PROFILING=ON ..
#
# will explicitly enable these targets from the command line at configure time
#

option(${PROJECT_NAME}_ENABLE_MEMORY_PROFILING "Builds targets with memory profiling" OFF)

find_package(Bloaty)

if (NOT Bloaty_FOUND AND ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
  message(STATUS "Bloaty is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.14.0)
  include(FetchContent)

  FetchContent_Declare(
    bloaty
    GIT_REPOSITORY https://github.com/google/bloaty.git
    GIT_TAG        origin/master
  )
  FetchContent_MakeAvailable(bloaty)
endif()

macro(eval_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with bloaty")
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()
endmacro()

function(swift_add_bloaty target)
  if (NOT ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
    return()
  endif()

  eval_target(${target})
  
  set(argOption SEGMENTS SECTIONS SYMBOLS COMPILEUNITS)
  set(argSingle SORT WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name bloaty-${target})
  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(reports_directory ${working_directory}/bloaty-reports)
  set(output_file ${target_name}.txt)

  unset(resource_options)
  if (x_SEGMENTS)
    list(APPEND resource_options segments)
  endif()

  if (x_SECTIONS)
    list(APPEND resource_options sections)
  endif()

  if (x_SYMBOLS)
    list(APPEND resource_options symbols)
  endif()

  if (x_COMPILEUNITS)
    list(APPEND resource_options compileunits)
  endif()

  if (DEFINED resource_options)
    string(REPLACE ";" "," resource_options "${resource_options}")
    list(PREPEND resource_options -d)
  endif()

  if (x_SORT)
    list(APPEND resource_options -s ${x_SORT})
  endif()

  add_custom_target(${target_name}
    COMMENT "bloaty is running on ${target}\ (output: \"${reports_directory}/${output_file}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} echo \"bloaty with options: ${resource_options}\" > ${reports_directory}/${output_file}
    COMMAND ${CMAKE_COMMAND} -E env $<TARGET_FILE:bloaty> ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS} >> ${reports_directory}/${output_file}
    DEPENDS ${target}
  )
endfunction()
