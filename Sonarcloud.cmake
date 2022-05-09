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

include(SwiftTargets) # expects variable _SWIFT_SOURCE_TARGETS_ to be available
include(TestTargets) # expects variable _SWIFT_TEST_TARGETS_ to be available

function(generate_sonar_project_properties file_path)
  if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    return()
  endif()

  list(LENGTH _SWIFT_TARGET_SOURCE_FILES_ source_files_size)
  list(LENGTH _SWIFT_TARGET_TEST_FILES_ test_files_size)

  if (source_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered source files")
  endif()

  if (test_files_size EQUAL 0)
    message(FATAL_ERROR "There are no registered test files")
  endif()

  file(WRITE ${file_path} "sonar.sourceEncoding=UTF-8\n")

  list(JOIN _SWIFT_TARGET_SOURCE_FILES_ ",\\\n  " sonar_sources)
  file(APPEND ${file_path} "sonar.sources=\\\n${sonar_sources}\n")

  list(JOIN _SWIFT_TARGET_TEST_FILES_ ",\\\n  " sonar_tests)
  file(APPEND ${file_path} "sonar.tests=\\\n${sonar_tests}\n")

endfunction()
