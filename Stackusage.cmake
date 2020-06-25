#
# OVERVIEW
#
# Stackusage is a dynamic memory profiling tool which measures the stack
# utilization of a running target and outputs the result to a file.
#
# USAGE
#
#   swift_add_stackusage(<target>
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with stackusage applied.
#
# WORKING_DIRECTORY
# This variable enables a user to change the output directory for the tools
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}`. Setting this option for
# target `starling-binary` to `/tmp`, outputs the results
# `/tmp/stackusage-reports/
#
# NOTE 
#
# Target needs to be run with a config-file
#

cmake_minimum_required(VERSION 3.11.0)

set(resource_name stackusage)
set(github_repo https://github.com/d99kris/stackusage.git)

include(FetchContent)
FetchContent_Declare(
  ${resource_name}
  GIT_REPOSITORY ${github_repo}
  GIT_TAG        origin/master
)
FetchContent_GetProperties(${resource_name})
if(NOT ${resource_name}_POPULATED)
  FetchContent_Populate(${resource_name})
  add_subdirectory(${${resource_name}_SOURCE_DIR} ${${resource_name}_BINARY_DIR})
endif()

macro(eval_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with \"${resource_name }\"")
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()
endmacro()

function(swift_add_${resource_name} target)
  eval_target(${target})
  
  set(argOption "")
  set(argSingle WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name ${resource_name}-${target})
  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(reports_directory ${working_directory}/${resource_name}-reports)
  set(output_file ${target_name}.txt)

  unset(resource_options)  
  list(APPEND resource_options -o ${reports_directory}/${output_file})

  add_custom_target(${target_name}
    COMMENT "${resource_name} is running on ${target}\ (output: \"${reports_directory}/${output_file}\")"
    COMMAND make
    WORKING_DIRECTORY ${${resource_name}_BINARY_DIR}
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory} ${${resource_name}_BINARY_DIR}/${resource_name} ${resource_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )
endfunction()
