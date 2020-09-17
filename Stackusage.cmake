#
# OVERVIEW
#
# Stackusage is a dynamic memory profiling tool which measures the stack
# utilization of a running target and outputs the result to a file.
#
# USAGE
#
#   swift_add_stackusage(<target>
#     [LOG_TOTAL_MEMORY]
#     [LOG_TOTAL_MEMORY_OPTIONS arg1 arg2 ...]
#     [NAME name]
#     [WORKING_DIRECTORY working_directory]
#     [REPORT_DIRECTORY report_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with stackusage applied. All targets created with
# `swift_add_stackusage` can be invoked by calling the common target 'do-all-stackusage'.
#
# LOG_TOTAL_MEMORY enables the creation of a log file where the output from Stackusage
# is parsed and the total number of allocated stack memory for each thread gets
# summarized and inserted.
#
# LOG_TOTAL_MEMORY_OPTIONS enables additional options when logging of total memory
# is enabled.
# * --input_file:  Set equal to a file path where an output file from Stackusage
#                  exists. [Default: `${report_directory}/${output_file}`]
# * --output_file: Set equal to a file path where the log file should be written.
#                  [Default: `${report_directory}/../memory_log.txt`]
# * --message:     Add a custom message that gets concatenated with the reported
#                  total memory. [Default: `"Stack memory usage:"`]
#
# NAME makes it possible to choose a custom name for the target, which
# is useful in situations using Google Test.
#
# WORKING_DIRECTORY changes the execution directory for the tool from the default
# folder `${CMAKE_CURRENT_BINARY_DIR}` to the given argument. For instance, if
# a user wants to utilize files located in a specific folder.
#
# REPORT_DIRECTORY changes the output directory for the tool from the default
# folder `${CMAKE_BINARY_DIR}/profiling/stackusage-reports` to the given argument.
# Example, using argument `/tmp`, outputs the result to `/tmp`.
#
# PROGRAM_ARGS specifies target arguments. Example, using a yaml-config
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

find_package(Stackusage)

if (NOT Stackusage_FOUND AND ${PROJECT_NAME}_ENABLE_PROFILING)
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
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with Stackusage")
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

function(swift_add_stackusage target)
  eval_stackusage_target(${target})
  
  set(argOption LOG_TOTAL_MEMORY)
  set(argSingle NAME WORKING_DIRECTORY REPORT_DIRECTORY)
  set(argMulti PROGRAM_ARGS LOG_TOTAL_MEMORY_OPTIONS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name stackusage-${target})
  if (x_NAME)
    set(target_name stackusage-${x_NAME})
  endif()
  set(output_file ${target_name}.txt)

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  set(report_directory ${CMAKE_BINARY_DIR}/profiling/stackusage-reports)
  if (x_REPORT_DIRECTORY)
    set(report_directory ${x_REPORT_DIRECTORY})
  endif()

  set(resource_options -o ${report_directory}/${output_file})
  
  if (NOT Stackusage_FOUND)
    add_custom_target(${target_name}
      COMMAND $(MAKE) --directory=${stackusage_BINARY_DIR}
      COMMENT "Stackusage is running on ${target}\ (output: \"${report_directory}/${output_file}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${stackusage_BINARY_DIR}/stackusage ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "Stackusage is running on ${target}\ (output: \"${report_directory}/${output_file}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${Stackusage_EXECUTABLE} ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  endif()

  if (NOT TARGET do-all-stackusage)
    add_custom_target(do-all-stackusage)
  endif()

  add_dependencies(do-all-stackusage ${target_name})
  add_dependencies(do-all-memory-profiling do-all-stackusage)

  if (x_LOG_TOTAL_MEMORY)
    set(memory_input_dir -i=${report_directory}/${output_file})
    set(memory_output_dir -o=${report_directory}/../memory_log.txt)
    set(memory_message "-m=Stack memory usage:")

    foreach (memory_option ${x_LOG_TOTAL_MEMORY_OPTIONS})
      if (${memory_option} MATCHES "--input_file")
        set(memory_input_dir ${memory_option})
      elseif (${memory_option} MATCHES "--output_file")
        set(memory_output_dir ${memory_option})
      elseif (${memory_option} MATCHES "--message")
        set(memory_message ${memory_option})
      endif()
    endforeach()

    unset(script_options)
    list(APPEND script_options ${memory_input_dir} ${memory_output_dir} ${memory_message})
    add_custom_command(TARGET ${target_name} POST_BUILD
      COMMAND python ${CMAKE_SOURCE_DIR}/cmake/common/scripts/parse_stackusage.py ${script_options}
    )
  endif()
endfunction()
