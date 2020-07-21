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
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with heaptrack applied. All created cmake targets can be
# invoked by calling the common target 'do-all-heaptrack'.
#
# NAME
# This variable makes it possible to choose a custom name for the target, which
# is useful in situations using Google Test.
#
# WORKING_DIRECTORY
# This variable changes the output directory for the tool from the default folder
# `${CMAKE_BINARY_DIR}/profiling/heaptrack-reports` to the given argument.
# Example, using argument `/tmp`, outputs the results to `/tmp/heaptrack-reports/
#
# PROGRAM_ARGS
# This variable specifies target arguments. Example, using a yaml-config
# with "--config example.yaml"
#
# NOTE 
#
# * Target needs to be run with a config-file.
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

find_package(Heaptrack)

if (NOT Heaptrack_FOUND AND ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
  message(STATUS "Heaptrack is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.11.0)
  include(FetchContent)

  FetchContent_Declare(
    heaptrack
    GIT_REPOSITORY https://github.com/KDE/heaptrack.git
    GIT_TAG        v1.1.0
    GIT_SHALLOW    TRUE
  )
  FetchContent_GetProperties(heaptrack)
  if(NOT heaptrack_POPULATED)
    FetchContent_Populate(heaptrack)
    set(current_build_test_state ${BUILD_TESTING})
    set(BUILD_TESTING OFF)
    add_subdirectory(${heaptrack_SOURCE_DIR} ${heaptrack_BINARY_DIR})
    set(BUILD_TESTING ${current_build_test_state}) 
  endif()
endif()

macro(eval_heaptrack_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with heaptrack")
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  if (CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
    return()
  endif()
endmacro()

function(swift_add_heaptrack target)
  eval_heaptrack_target(${target})
  
  set(argOption "")
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name heaptrack-${target})
  if (x_NAME)
    set(target_name heaptrack-${x_NAME})
  endif()

  set(working_directory ${CMAKE_BINARY_DIR}/profiling)
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(reports_directory ${working_directory}/heaptrack-reports)

  if (NOT Heaptrack_FOUND)
    add_custom_target(${target_name}
      COMMENT "heaptrack is running on ${target}\ (output: \"${reports_directory}\")"
      COMMAND $(MAKE)
      WORKING_DIRECTORY ${heaptrack_BINARY_DIR}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${heaptrack_BINARY_DIR}/bin/heaptrack $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "heaptrack is running on ${target}\ (output: \"${reports_directory}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${Heaptrack_EXECUTABLE} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  endif()

  if (NOT TARGET do-all-heaptrack)
    add_custom_target(do-all-heaptrack)
  endif()
  add_dependencies(do-all-heaptrack ${target_name})
endfunction()
