#
# OVERVIEW
#
# Heaptrack is a dynamic memory profiling tool which measures the heap utilization
# of a target binary and outputs the result to a file.
#
# USAGE
#
#   swift_add_heaptrack(<target>
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with heaptrack applied.
#
# WORKING_DIRECTORY
# This variable enables a user to change the output directory for the tools
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}`. Setting this option for
# target `starling-binary` to `/tmp`, outputs the results
# `/tmp/heaptrack-reports/
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

find_package(Heaptrack)

if (NOT Heaptrack_FOUND AND ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
  message(STATUS "Heaptrack is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.11.0)
  include(FetchContent)

  FetchContent_Declare(
    heaptrack
    GIT_REPOSITORY https://github.com/KDE/heaptrack.git
    GIT_TAG        origin/master
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

macro(eval_target target)
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
endmacro()

function(swift_add_heaptrack target)
  if (NOT ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
    return()
  endif()
  
  eval_target(${target})
  
  set(argOption "")
  set(argSingle WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name heaptrack-${target})
  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(reports_directory ${working_directory}/heaptrack-reports)

  if (NOT Heaptrack_FOUND)
    add_custom_target(${target_name}
      COMMENT "heaptrack is running on ${target}\ (output: \"${reports_directory}\")"
      COMMAND $(MAKE)
      WORKING_DIRECTORY ${heaptrack_BINARY_DIR}
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${heaptrack_BINARY_DIR}/bin/heaptrack $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "heaptrack is running on ${target}\ (output: \"${reports_directory}\")"
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${Heaptrack_EXECUTABLE} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  endif()
endfunction()
