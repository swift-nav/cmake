#
# OVERVIEW
#
# Heaptrack is a dynamic memory profiling tool which measures the heap utilization
# of a target binary and outputs the result to a file.
#
# USAGE
#
#   swift_add_heaptrack(<target>
#     [NAME name]
#     [WORKING_DIRECTORY working_directory]
#     [REPORT_DIRECTORY report_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with heaptrack applied. All targets created with
# `swift_add_heaptrack` can be invoked by calling the common target 'do-all-heaptrack'.
#
# NAME
# This variable makes it possible to choose a custom name for the target, which
# is useful in situations using Google Test.
#
# WORKING_DIRECTORY
# This variable changes the execution directory for the tool from the default
# folder `${CMAKE_CURRENT_BINARY_DIR}` to the given argument. For instance, if
# a user wants to utilize files located in a specific folder.
#
# REPORT_DIRECTORY
# This variable changes the output directory for the tool from the default folder
# `${CMAKE_BINARY_DIR}/profiling/heaptrack-reports` to the given argument.
# Example, using argument `/tmp`, outputs the results to `/tmp`.
#
# PROGRAM_ARGS
# This variable specifies target arguments. Example, using a yaml-config
# with "--config example.yaml".
#
# NOTE
#
# * Target needs to be run with a config-file.
# * A cmake option is available to control whether targets should be built,
# with the name ${PROJECT_NAME}_ENABLE_PROFILING.
#
# Running
#
# cmake -D<project>_ENABLE_PROFILING=ON ..
#
# will explicitly enable these targets from the command line at configure time.
#

option(${PROJECT_NAME}_ENABLE_PROFILING "Builds targets with profiling applied" OFF)

find_package(Heaptrack)

if (NOT Heaptrack_FOUND AND ${PROJECT_NAME}_ENABLE_PROFILING)
  message(STATUS "Heaptrack is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.14.0)
  include(FetchContent)

  FetchContent_Declare(
    heaptrack
    GIT_REPOSITORY https://github.com/KDE/heaptrack.git
    GIT_TAG        v1.2.0
    GIT_SHALLOW    TRUE
  )
  FetchContent_MakeAvailable(heaptrack)
endif()

macro(eval_heaptrack_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with Heaptrack")
  endif()

  if (NOT (${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME} AND
           ${PROJECT_NAME}_ENABLE_PROFILING)
      OR CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT TARGET do-all-memory-profiling)
    add_custom_target(do-all-memory-profiling)
  endif()
endmacro()

function(swift_add_heaptrack target)
  eval_heaptrack_target(${target})
  
  set(argOption "")
  set(argSingle NAME WORKING_DIRECTORY REPORT_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name heaptrack-${target})
  if (x_NAME)
    set(target_name heaptrack-${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  set(report_directory ${CMAKE_BINARY_DIR}/profiling/heaptrack-reports)
  if (x_REPORT_DIRECTORY)
    set(report_directory ${x_REPORT_DIRECTORY})
  endif()

  if (NOT Heaptrack_FOUND)
    add_custom_target(${target_name}
      COMMAND $(MAKE) --directory=${heaptrack_BINARY_DIR}
      COMMENT "Heaptrack is running on ${target}\ (output: \"${report_directory}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${heaptrack_BINARY_DIR}/bin/heaptrack $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      COMMAND mv ${working_directory}/heaptrack* ${report_directory}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "Heaptrack is running on ${target}\ (output: \"${report_directory}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${Heaptrack_EXECUTABLE} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      COMMAND mv ${working_directory}/heaptrack* ${report_directory}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  endif()

  if (NOT TARGET do-all-heaptrack)
    add_custom_target(do-all-heaptrack)
  endif()

  add_dependencies(do-all-heaptrack ${target_name})
  add_dependencies(do-all-memory-profiling do-all-heaptrack)
endfunction()
