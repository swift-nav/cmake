#
# Copyright (C) 2022 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

include(SwiftTargets) # expects global properties SWIFT_EXECUTABLE_TARGETS and SWIFT_LIBRARY_TARGETS to be defined
include(TestTargets) # expects global properties SWIFT_UNIT_TEST_TARGETS and SWIFT_INTEGRATION_TEST_TARGETS to be defined

function(transform_sonarcloud_source_files output_variable target)
  #
  # Based off of https://cmake.org/cmake/help/latest/prop_tgt/SOURCES.html we
  # need to correcty interpret the SOURCES properties to be able to transform
  # them into what sonarcloud project properties is comfortable with (ie. paths
  # from project source directory
  #
  get_target_property(target_binary_dir ${target} BUILD_DIR)
  get_target_property(target_source_dir ${target} SOURCE_DIR)

  unset(source_files)
  foreach (source_file IN LISTS ARGN)
    get_source_file_property(is_build_generated_file ${target_binary_dir}/${source_file} GENERATED)

    if(IS_ABSOLUTE ${source_file})
      file(RELATIVE_PATH source_file ${PROJECT_SOURCE_DIR} ${source_file})
      list(APPEND source_files ${source_file})
      continue()
    endif()

    if (is_build_generated_file)
      set(source_file ${target_binary_dir}/${source_file})
      file(RELATIVE_PATH source_file ${PROJECT_SOURCE_DIR} ${source_file})
      list(APPEND source_files ${source_file})
      continue()
    endif()

    if (EXISTS ${target_source_dir}/${source_file})
      set(source_file ${target_source_dir}/${source_file})
      file(RELATIVE_PATH source_file ${PROJECT_SOURCE_DIR} ${source_file})
      list(APPEND source_files ${source_file})
      continue()
    endif()

    if (source_file MATCHES "^\\$<.+>$")
      list(APPEND source_files ${source_file})
      continue()
    endif()

    message(WARNING "Sonarcloud is missing source file \"${source_file}\" for target ${target}")
    list(APPEND source_files ${source_file})
  endforeach()

  set(${output_variable} ${source_files} PARENT_SCOPE)
endfunction()

function(transform_sonarcloud_include_directories output_variable target)
  unset(include_directories)

  foreach (include_directory IN LISTS ARGN)
    if(IS_ABSOLUTE ${include_directory})
      file(RELATIVE_PATH include_directory ${PROJECT_SOURCE_DIR} ${include_directory})
      list(APPEND include_directories ${include_directory})
      continue()
    endif()

    if (include_directory MATCHES "^\\$<INSTALL_INTERFACE:.+>$")
      # ignoring installation interfaces
      continue()
    endif()

    if (include_directory MATCHES "^\\$<.+>$")
      list(APPEND include_directories ${include_directory})
      continue()
    endif()

    message(WARNING "Sonarcloud is missing include directory \"${include_directory}\" for target ${target}")
    list(APPEND include_directories ${include_directory})
  endforeach()

  set(${output_variable} ${include_directories} PARENT_SCOPE)
endfunction()

function(extract_sonarcloud_project_files output_variable)
  unset(project_files)

  foreach (target IN LISTS ARGN)
    get_target_property(swift_project ${target} SWIFT_PROJECT)
    if(NOT ${swift_project} STREQUAL ${PROJECT_NAME})
      continue()
    endif()

    get_target_property(target_source_files ${target} SOURCES)
    get_target_property(target_include_directories ${target} INCLUDE_DIRECTORIES)
    get_target_property(target_interface_include_directories ${target} INTERFACE_INCLUDE_DIRECTORIES)

    foreach(variable IN ITEMS target_source_files target_include_directories target_interface_include_directories)
      if (NOT ${variable})
        unset(${variable})
      endif()
    endforeach()

    transform_sonarcloud_source_files(target_source_files ${target} ${target_source_files})
    transform_sonarcloud_include_directories(target_include_directories ${target} ${target_include_directories})
    transform_sonarcloud_include_directories(target_interface_include_directories ${target} ${target_interface_include_directories})

    list(APPEND project_files ${target_source_files})
    list(APPEND project_files ${target_include_directories})
    list(APPEND project_files ${target_interface_include_directories})
  endforeach()

  if (project_files)
    list(SORT project_files)
    list(REMOVE_DUPLICATES project_files)
  endif()

  set(${output_variable} ${project_files} PARENT_SCOPE)
endfunction()

function(generate_sonarcloud_project_properties sonarcloud_project_properties_path)
  if (NOT IS_ABSOLUTE ${sonarcloud_project_properties_path})
    message(FATAL_ERROR "Function \"generate_sonarcloud_project_properties\""
           "only accepts sonarcloud project properties output as absolute paths")
  endif()

  if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    return()
  endif()

  get_property(swift_executable_targets GLOBAL PROPERTY SWIFT_EXECUTABLE_TARGETS)
  get_property(swift_library_targets GLOBAL PROPERTY SWIFT_LIBRARY_TARGETS)
  get_property(swift_unit_test_targets GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS)
  get_property(swift_integration_test_targets GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS)

  extract_sonarcloud_project_files(source_files ${swift_executable_targets} ${swift_library_targets})
  extract_sonarcloud_project_files(test_files ${swift_unit_test_targets} ${swift_integration_test_targets})

  #
  # In the case were we are directly compiling the source code for mocking, we
  # need to strip off the source files.
  #
  list(REMOVE_ITEM test_files ${source_files})

  list(LENGTH source_files source_files_size)
  list(LENGTH test_files test_files_size)

  if (source_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift source targets")
  endif()

  if (test_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift test targets")
  endif()

  set(sonarcloud_project_properties_content "sonar.sourceEncoding=UTF-8\n")

  list(JOIN source_files ",\\\n  " sonar_sources)
  string(APPEND sonarcloud_project_properties_content "sonar.sources=\\\n  ${sonar_sources}\n")

  list(JOIN test_files ",\\\n  " sonar_tests)
  string(APPEND sonarcloud_project_properties_content "sonar.tests=\\\n  ${sonar_tests}\n")

  file(GENERATE
    OUTPUT "${sonarcloud_project_properties_path}"
    CONTENT "${sonarcloud_project_properties_content}"
  )

endfunction()
