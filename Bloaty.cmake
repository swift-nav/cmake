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
#     [REPORT_DIRECTORY report_directory]
#   )
#
# Call this function to create a new cmake target which runs the `target`'s
# executable binary with bloaty applied. All targets created with
# `swift_add_bloaty` can be invoked by calling the common target 'do-all-bloaty'.
#
# BLOATY OPTIONS
#
#  * SEGMENTS:     Outputs what the run-time loader uses to determine what
#                  parts of the binary needs to be loaded/mapped into memory.
#  * SECTIONS:     Outputs the binary in finer details structured in different sections.
#  * SYMBOLS:      Outputs individual functions or variables.
#  * COMPILEUNITS: Outputs what compile unit (and corresponding source file)
#                  each bit of the binary came from.
#
#  * NUM: Set how many rows to show per level before collapsing into '[other]'.
#         Set to '0' for unlimited, default: '20'.
#
#  * SORT:
#      vm   - Sort the vm size column from largest to smallest and tells you
#             how much space the binary will take when loaded into memory.
#      file - Sort the file size column from largest to smallest and tells you
#             how much space the binary is taking on disk.
#      both - Default, sorts by max(vm, file).
#
# WORKING_DIRECTORY
# This variable changes the execution directory for the tool from the default
# folder `${CMAKE_CURRENT_BINARY_DIR}` to the given argument. For instance, if
# a user wants to utilize files located in a specific folder.
#
# REPORT_DIRECTORY
# This variable changes the output directory for the tool from the default folder
# `${CMAKE_BINARY_DIR}/profiling/bloaty-reports` to the given argument.
# Example, using argument `/tmp`, outputs the result to `/tmp`.
#
# NOTE
#
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

find_package(Bloaty)

if (NOT Bloaty_FOUND AND ${PROJECT_NAME}_ENABLE_PROFILING)
  message(STATUS "Bloaty is not installed on system, will fetch content from source")

  cmake_minimum_required(VERSION 3.14.0)
  include(FetchContent)

  FetchContent_Declare(
    bloaty
    GIT_REPOSITORY https://github.com/google/bloaty.git
    GIT_TAG        v1.1
    GIT_SHALLOW    TRUE
  )
  FetchContent_MakeAvailable(bloaty)
endif()

macro(eval_bloaty_target target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)
  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for profiling with Bloaty")
  endif()

  if (NOT (${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME} AND
           ${PROJECT_NAME}_ENABLE_PROFILING))
    return()
  endif()

  if (NOT TARGET do-all-memory-profiling)
    add_custom_target(do-all-memory-profiling)
  endif()
endmacro()

function(swift_add_bloaty target)
  eval_bloaty_target(${target})
  
  set(argOption SEGMENTS SECTIONS SYMBOLS COMPILEUNITS)
  set(argSingle NUM SORT WORKING_DIRECTORY REPORT_DIRECTORY)
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name bloaty-${target})
  set(output_file ${target_name}.txt)

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  set(report_directory ${CMAKE_BINARY_DIR}/profiling/bloaty-reports)
  if (x_REPORT_DIRECTORY)
    set(report_directory ${x_REPORT_DIRECTORY})
  endif()

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
    set(resource_options -d ${resource_options})
  endif()

  if (DEFINED x_NUM)
    list(APPEND resource_options -n ${x_NUM})
  endif()

  if (x_SORT)
    list(APPEND resource_options -s ${x_SORT})
  endif()

  if (NOT Bloaty_FOUND)
    add_custom_target(${target_name}
      COMMAND $(MAKE) --directory=${bloaty_BINARY_DIR}
      COMMENT "Bloaty is running on ${target}\ (output: \"${report_directory}/${output_file}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${CMAKE_COMMAND} -E echo \"bloaty with options: ${resource_options}\" > ${report_directory}/${output_file}
      COMMAND ${bloaty_BINARY_DIR}/bloaty ${resource_options} $<TARGET_FILE:${target}> >> ${report_directory}/${output_file}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  else()
    add_custom_target(${target_name}
      COMMENT "Bloaty is running on ${target}\ (output: \"${report_directory}/${output_file}\")"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}
      COMMAND ${CMAKE_COMMAND} -E echo \"bloaty with options: ${resource_options}\" > ${report_directory}/${output_file}
      COMMAND ${Bloaty_EXECUTABLE} ${resource_options} $<TARGET_FILE:${target}> >> ${report_directory}/${output_file}
      WORKING_DIRECTORY ${working_directory}
      DEPENDS ${target}
    )
  endif()

  if (NOT TARGET do-all-bloaty)
    add_custom_target(do-all-bloaty)
  endif()

  add_dependencies(do-all-bloaty ${target_name})
  add_dependencies(do-all-memory-profiling do-all-bloaty)
endfunction()
