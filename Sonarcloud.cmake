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

function(sonarcloud_to_project_directory output_variable)
  unset(paths)
  foreach (path IN ITEMS ${ARGN})
    if(IS_ABSOLUTE ${path})
      file(RELATIVE_PATH path ${PROJECT_SOURCE_DIR} ${path})
      list(APPEND paths ${path})
    else()
      list(APPEND paths ${path})
    endif()
  endforeach()
  set(${output_variable} ${paths} PARENT_SCOPE)
endfunction()

function(extract_sonarcloud_project_files output_variable)
  unset(files)

  foreach (target IN ITEMS ${ARGN})
    get_target_property(swift_project ${target} SWIFT_PROJECT)
    if(NOT swift_project STREQUAL ${PROJECT_NAME})
      continue()
    endif()

    get_target_property(target_source_files ${target} SOURCES)
    get_target_property(target_include_directories ${target} INCLUDE_DIRECTORIES)
    get_target_property(target_interface_include_directories ${target} INTERFACE_INCLUDE_DIRECTORIES)

    sonarcloud_to_project_directory(target_source_files ${target_source_files})
    sonarcloud_to_project_directory(target_include_directories ${target_include_directories})
    sonarcloud_to_project_directory(target_interface_include_directories ${target_interface_include_directories})

    list(APPEND files ${target_source_files})
    list(APPEND files ${target_include_directories})
    list(APPEND files ${target_interface_include_directories})
  endforeach()

  list(SORT files)
  list(REMOVE_DUPLICATES files)

  set(${output_variable} ${files} PARENT_SCOPE)
endfunction()

function(generate_sonarcloud_project_properties file_path)
  if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    return()
  endif()

  get_property(swift_executable_targets GLOBAL PROPERTY SWIFT_EXECUTABLE_TARGETS)
  get_property(swift_library_targets GLOBAL PROPERTY SWIFT_LIBRARY_TARGETS)
  get_property(swift_unit_test_targets GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS)
  get_property(swift_integration_test_targets GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS)

  extract_sonarcloud_project_files(source_files ${swift_executable_targets} ${swift_library_targets})
  extract_sonarcloud_project_files(test_files ${swift_unit_test_targets} ${swift_integration_test_targets})

  list(LENGTH source_files source_files_size)
  list(LENGTH test_files test_files_size)

  if (source_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift source targets")
  endif()

  if (test_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift test targets")
  endif()

  file(WRITE ${file_path} "sonar.sourceEncoding=UTF-8\n")

  list(JOIN source_files ",\\\n  " sonar_sources)
  file(APPEND ${file_path} "sonar.sources=\\\n  ${sonar_sources}\n")

  list(JOIN test_files ",\\\n  " sonar_tests)
  file(APPEND ${file_path} "sonar.tests=\\\n  ${sonar_tests}\n")

endfunction()
