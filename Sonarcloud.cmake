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

function(generate_sonar_project_properties file_path)
  if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR})
    return()
  endif()

  get_property(swift_executable_targets GLOBAL PROPERTY SWIFT_EXECUTABLE_TARGETS)
  get_property(swift_library_targets GLOBAL PROPERTY SWIFT_LIBRARY_TARGETS)

  get_property(swift_unit_test_targets GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS)
  get_property(swift_integration_test_targets GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS)

  set(swift_source_targets ${swift_executable_targets} ${swift_library_targets})
  list(LENGTH swift_source_targets swift_source_targets_size)

  set(swift_test_targets ${swift_unit_test_targets} ${swift_integration_test_targets})
  list(LENGTH swift_test_targets swift_test_targets_size)

  if (swift_source_targets_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift source targets")
  endif()

  if (swift_test_targets_size EQUAL 0)
    message(FATAL_ERROR "There are no registered swift test targets")
  endif()

  file(WRITE ${file_path} "sonar.sourceEncoding=UTF-8\n")

  list(JOIN swift_source_targets ",\\\n  " sonar_sources)
  file(APPEND ${file_path} "sonar.sources=\\\n${sonar_sources}\n")

  list(JOIN swift_test_targets ",\\\n  " sonar_tests)
  file(APPEND ${file_path} "sonar.tests=\\\n${sonar_tests}\n")

endfunction()
