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
include(TestTargets) # expects global properties SWIFT_TEST_TARGETS, SWIFT_UNIT_TEST_TARGETS and SWIFT_INTEGRATION_TEST_TARGETS to be defined

set(_sonarcloud_newline "\\\n  ")

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
      list(APPEND source_files ${source_file})
      continue()
    endif()

    if (is_build_generated_file)
      list(APPEND source_files ${target_binary_dir}/${source_file})
      continue()
    endif()

    if (EXISTS ${target_source_dir}/${source_file})
      list(APPEND source_files ${target_source_dir}/${source_file})
      continue()
    endif()

    if (source_file MATCHES "^\\$<.+>$")
      list(APPEND source_files "$<$<BOOL:${source_file}>:$<JOIN:${source_file},$<COMMA>${_sonarcloud_newline}>>")
      continue()
    endif()

    message(WARNING "Sonarcloud is missing source file \"${source_file}\" for target ${target}")
  endforeach()

  set(${output_variable} ${source_files} PARENT_SCOPE)
endfunction()

function(transform_sonarcloud_include_directories output_variable target)
  unset(include_directories)

  foreach (include_directory IN LISTS ARGN)
    if(IS_ABSOLUTE ${include_directory})
      list(APPEND include_directories ${include_directory})
      continue()
    endif()

    if (include_directory MATCHES "^\\$<INSTALL_INTERFACE:.+>$")
      # ignoring installation interfaces
      continue()
    endif()

    if (include_directory MATCHES "^\\$<.+>$")
      list(APPEND include_directories "$<$<BOOL:${include_directory}>:$<JOIN:${include_directory},$<COMMA>${_sonarcloud_newline}>>")
      continue()
    endif()

    message(WARNING "Sonarcloud is missing include directory \"${include_directory}\" for target ${target}")
  endforeach()

  set(${output_variable} ${include_directories} PARENT_SCOPE)
endfunction()

function(extract_sonarcloud_project_files output_project_source_files output_project_include_directories)
  unset(project_source_files)
  unset(project_include_directories)

  foreach (target IN LISTS ARGN)
    get_target_property(target_type ${target} TYPE)
    if (${target_type} STREQUAL "INTERFACE_LIBRARY")
      get_target_property(swift_project ${target} INTERFACE_SWIFT_PROJECT)
    else()
      get_target_property(swift_project ${target} SWIFT_PROJECT)
    endif()

    if(NOT ${swift_project} STREQUAL ${PROJECT_NAME})
      continue()
    endif()

    if (NOT ${target_type} STREQUAL "INTERFACE_LIBRARY")
      get_target_property(target_source_files ${target} SOURCES)
      if (target_source_files)
        transform_sonarcloud_source_files(target_source_files ${target} ${target_source_files})
      else()
        unset(target_source_files)
      endif()

      get_target_property(target_include_directories ${target} INCLUDE_DIRECTORIES)
      if (target_include_directories)
        transform_sonarcloud_include_directories(target_include_directories ${target} ${target_include_directories})
      else()
        unset(target_include_directories)
      endif()
    endif()

    get_target_property(target_interface_include_directories ${target} INTERFACE_INCLUDE_DIRECTORIES)
    if (target_interface_include_directories)
      transform_sonarcloud_include_directories(target_interface_include_directories ${target} ${target_interface_include_directories})
    else()
      unset(target_interface_include_directories)
    endif()

    list(APPEND project_source_files ${target_source_files})
    list(APPEND project_include_directories ${target_include_directories})
    list(APPEND project_include_directories ${target_interface_include_directories})
  endforeach()

  if (project_source_files)
    list(SORT project_source_files)
    list(REMOVE_DUPLICATES project_source_files)
  endif()

  if (project_include_directories)
    list(SORT project_include_directories)
    list(REMOVE_DUPLICATES project_include_directories)
  endif()

  set(${output_project_source_files} ${project_source_files} PARENT_SCOPE)
  set(${output_project_include_directories} ${project_include_directories} PARENT_SCOPE)
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
  get_property(swift_test_targets GLOBAL PROPERTY SWIFT_TEST_TARGETS)
  get_property(swift_unit_test_targets GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS)
  get_property(swift_integration_test_targets GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS)

  extract_sonarcloud_project_files(source_source_files source_include_directories ${swift_executable_targets} ${swift_library_targets})
  extract_sonarcloud_project_files(test_source_files test_include_directories ${swift_test_targets} ${swift_unit_test_targets} ${swift_integration_test_targets})

  set(sonarcloud_project_properties_content "sonar.sourceEncoding=UTF-8\n")

  set(source_files ${source_source_files} ${source_include_directories})
  list(JOIN source_files ",${_sonarcloud_newline}" sonar_sources)
  string(APPEND sonarcloud_project_properties_content "sonar.inclusions=${_sonarcloud_newline}${sonar_sources}\n")

  set(test_files ${test_source_files})
  list(JOIN test_files ",${_sonarcloud_newline}" sonar_tests)
  string(APPEND sonarcloud_project_properties_content "sonar.tests.inclusions=${_sonarcloud_newline}${sonar_tests}\n")

  file(GENERATE
    OUTPUT "${sonarcloud_project_properties_path}"
    CONTENT "${sonarcloud_project_properties_content}"
  )

endfunction()
