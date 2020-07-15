#
# OVERVIEW
#
# Stackusage is a dynamic memory profiling tool which measures the stack
# utilization of a running target and outputs the result to a file.
#
# USAGE
#
#   swift_add_stackusage(<target>
#     [NAME name]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with stackusage applied.
#
# NAME
# This variable makes it possible to choose a custom name for the target, which
# is useful in situations using Google Test.
#
# WORKING_DIRECTORY
# This variable changes the output directory for the tool
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}` to the given argument.
# Example, using argument `/tmp`, outputs the results to
# `/tmp/stackusage-reports/
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

find_package(Stackusage)

if (NOT Stackusage_FOUND AND ${PROJECT_NAME}_ENABLE_MEMORY_PROFILING)
  message(STATUS "Stackusage is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.14.0)
  include(FetchContent)

  FetchContent_Declare(
    stackusage
    GIT_REPOSITORY https://github.com/d99kris/stackusage.git
    GIT_TAG        v1.11
    GIT_SHALLOW    TRUE
  )
  FetchContent_MakeAvailable(stackusage)
endif()

macro(eval_stackusage_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with stackusage")
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

function(swift_add_stackusage target)
  eval_stackusage_target(${target})
  
  set(argOption "")
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name stackusage-${target})
  if (x_NAME)
    set(target_name stackusage-${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(reports_directory ${working_directory}/stackusage-reports)
  set(output_file ${target_name}.txt)

  unset(resource_options)  
  list(APPEND resource_options -o ${reports_directory}/${output_file})
  
  if (NOT Stackusage_FOUND)
    add_custom_target(${target_name}
      COMMENT "stackusage is running on ${target}\ (output: \"${reports_directory}/${output_file}\")"
      COMMAND $(MAKE)
      WORKING_DIRECTORY ${stackusage_BINARY_DIR}
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${stackusage_BINARY_DIR}/stackusage ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "stackusage is running on ${target}\ (output: \"${reports_directory}/${output_file}\")"
      COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
      COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${Stackusage_EXECUTABLE} ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      DEPENDS ${target}
    )
  endif()
endfunction()
