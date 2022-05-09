#
# Copyright (C) 2021 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

# Helper functions for creating cmake targets to build and run test suites
#
# This module defines several cmake targets which support building and running
# tests. 2 external function are available with subtle differences,
# swift_add_test() and swift_add_test_runner()
#
# swift_add_test() defines a new test suite to be built from a list of sources
# with options for linking libraries and including extra source directories.
# Basic usage is
#
# swift_add_test(test-suite-name
#    <UNIT_TEST|INTEGRATION_TEST>
#    VALGRIND_MEMCHECK
#    SRCS
#      main.cc
#      ...more source files
#    LINK
#      ...link libraries
#    INCLUDE
#      ...extra include directories
#    WORKING_DIRECTORY <path>
#    )
#
# This will create 2 cmake targets
# - test-suite-name - an executable composed of the specified source files,
#   linked against the specified libraries
# - do-test-suite-name - A custom target which will execute the above target
#
# UNIT_TEST or INTEGRATION_TEST options should be specified for each function
# call, it serves to categorize if the test executable is a unit test or an
# integration test. If either option is not specified, a cmake warning will be
# raised. If both are specified, a cmake error will be raised.
#
# VALGRIND_MEMCHECK, LINK, INCLUDE, and WORKING_DIRECTORY are optional
# parameters.
#
# VALGRIND_MEMCHECK is a convenience parameter that will call
# swift_add_valgrind_memcheck with the following parameters:
#
# swift_add_valgrind_memcheck(${target}
#   LEAK_CHECK full
#   WORKING_DIRECTORY <path>
#   SHOW_REACHABLE
#   UNDEF_VALUE_ERRORS
#   TRACK_ORIGINS
#   CHILD_SILENT_AFTER_FORK
#   TRACE_CHILDREN
#   GENERATE_JUNIT_REPORT
# )
#
# This parameter is not allowed to be set with INTEGRATION_TEST.
# See Valgrind.cmake for the full documentation of this function.
#
# If WORKING_DIRECTORY is not specified the tests will be run in
# ${CMAKE_CURRENT_BINARY_DIR}
#
# All tests will have their language standards set to the swift default by
# using the LanguageStandards module, and have code coverage enabled
#
# An optional parameter PARALLEL can be passed which will create an additional
# target to run tests in parallel.
#
# swift_add_test(test-suite-name
#   PARALLEL
#   SRCS ...srcs...
#   )
#
# will create an extra target parallel-test-suite-name. This target only makes
# sense for gtest based test suites and uses the parallel test helper program
# from the googletest package. The non-parallel target is always created.
#
# The other function, swift_add_test_runner(), can be used to create a do-...
# target which points at some other command. This can be used to invoke a test
# which is actually a shell script or some other executable which is available
# but not built from source
#
# swift_add_test_runner(test-suite-name
#    <UNIT_TEST|INTEGRATION_TEST>
#    COMMAND <testing command> <arguments>
#    WORKING_DIRECTORY <path>
#    DEPENDS <optional list of cmake targets on which this test depend>
#    )
#
# This will create just a single target:
# - do-test-suite-name - Execute the given command
#
# UNIT_TEST and INTEGRATION_TEST options work identical to swift_add_test
#
# WORKING_DIRECTORY and DEPENDS are optional arguments. WORKING_DIRECTORY defaults
# to ${CMAKE_CURRENT_BINARY_DIR}
#
# Both functions can take an optional argument COMMENT which will print out a
# nicer status message when the test is run
#
# swift_add_test(test-suite-name
#    SRCS <list of source>
#    COMMENT "Performing some tests"
#    )
#
# This module will create some extra global targets to build and run all tests
# - build-all-tests - Build all specified tests
# - do-all-tests - Execute all specified tests (includes do-all-unit-tests and
#   do-all-integration-tests)
# - do-all-unit-tests - Executes all tests marked with the UNIT_TEST option
# - do-all-integration_tests - Executes all tests marked with the
#   INTEGRATION_TEST option
#
# If the PARALLEL option was specified for swift_add_test, than the unit tests
# will be run in parallel when executing do-all-tests.
#
# In addition tests can be added with the option POST_BUILD which will cause
# cmake to execute those tests as part of the 'all' target. To assist this
# functionality this module will create some extra targets
#
# - build-post-build-tests - Build all tests which have been marked as POST_BUILD
# - do-post-build-tests - Run all tests which have been marked as POST_BUILD
#
# To specify a test to be run as part of 'make all' simply pass the option POST_BUILD
#
# swift_add_test(test-suite-name
#    POST_BUILD
#    SRCS ...srcs
#    LINK ...libraries
#    )
#
# or
#
# swift_add_test_runner(test-suite-name
#    POST_BUILD
#    COMMAND <path to executable>
#    )
#
# NOTE: using POST_BUILD option is not advised as it will increase build time
#
# Dependency chains are set up so that post build tests will be run towards the
# end of the build process. Cmake lacks functionality to run commands as a
# post-build step so it is not guaranteed that tests will run after everything
# has been built, just that they will run very late in the process. This should
# give a chance for compiler errors to surface before tests are run
#
# A command line option AUTORUN_TESTS can be specified (ON by default) to
# control whether or not tests run as part of 'make all'.
#
# cmake -DAUTORUN_TESTS=OFF <path to source>
#
# will disable post build tests from running as part of 'make all'. The post-build
# targets will still be created and can be invoked manually.
#

include(LanguageStandards)
include(CodeCoverage)

option(AUTORUN_TESTS "Automatically run post-build tests as part of 'all' target" ON)

macro(swift_create_test_targets)
  if(AUTORUN_TESTS)
    set(autorun ALL)
  endif()

  if(NOT TARGET build-all-tests)
    add_custom_target(build-all-tests)
  endif()

  if(NOT TARGET do-all-tests)
    add_custom_target(do-all-tests)
  endif()

  if(NOT TARGET build-post-build-tests)
    add_custom_target(build-post-build-tests ${autorun})
  endif()

  if(NOT TARGET do-post-build-tests)
    add_custom_target(do-post-build-tests ${autorun})
  endif()
endmacro()

function(swift_add_test_runner target)
  set(argOption "INTEGRATION_TEST" "POST_BUILD" "UNIT_TEST")
  set(argSingle "COMMENT" "WORKING_DIRECTORY")
  set(argMulti "COMMAND" "DEPENDS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test_runner unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  if(x_WORKING_DIRECTORY)
    set(wd WORKING_DIRECTORY ${x_WORKING_DIRECTORY})
  endif()

  if (NOT x_INTEGRATION_TEST AND NOT x_UNIT_TEST)
    message(WARNING "Missing INTEGRATION_TEST or UNIT_TEST option")
  elseif(x_INTEGRATION_TEST AND x_UNIT_TEST)
    message(FATAL_ERROR "Both INTEGRATION_TEST and UNIT_TEST option were specified, you can only specify one")
  endif()

  if (NOT ${PROJECT_NAME}_BUILD_TESTS)
    return()
  endif()

  swift_create_test_targets()

  add_custom_target(
    do-${target}
    COMMAND ${x_COMMAND}
    ${wd}
    COMMENT "Running ${x_COMMENT}"
  )
  add_dependencies(do-all-tests do-${target})
  if(x_DEPENDS)
    add_dependencies(do-${target} ${x_DEPENDS})
  endif()

  if (x_INTEGRATION_TEST)
    if (NOT TARGET do-all-integration-tests)
      add_custom_target(do-all-integration-tests)
    endif()

    add_dependencies(do-all-integration-tests do-${target})
  endif()

  if (x_UNIT_TEST)
    if (NOT TARGET do-all-unit-tests)
      add_custom_target(do-all-unit-tests)
    endif()

    add_dependencies(do-all-unit-tests do-${target})
  endif()

  if(x_POST_BUILD)
    add_custom_target(post-build-${target}
      COMMAND ${x_COMMAND}
      ${wd}
      COMMENT "Running post build ${x_COMMENT}"
    )
    add_dependencies(do-post-build-tests post-build-${target})
    add_dependencies(post-build-${target} build-post-build-tests)
    if(x_DEPENDS)
      add_dependencies(post-build-${target} ${x_DEPENDS})
      add_dependencies(build-post-build-tests ${x_DEPENDS})
    endif()
  endif()
endfunction()

function(swift_add_test target)
  set(argOption "INTEGRATION_TEST" "PARALLEL" "POST_BUILD" "UNIT_TEST" "VALGRIND_MEMCHECK")
  set(argSingle "COMMENT" "WORKING_DIRECTORY")
  set(argMulti "SRCS" "LINK" "INCLUDE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_SRCS)
    message(FATAL_ERROR "swift_add_test must be passed at least one source file")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  if(x_WORKING_DIRECTORY)
    set(wd WORKING_DIRECTORY ${x_WORKING_DIRECTORY})
  endif()

  if (NOT x_INTEGRATION_TEST AND NOT x_UNIT_TEST)
    message(WARNING "Missing INTEGRATION_TEST or UNIT_TEST option")
  elseif(x_INTEGRATION_TEST AND x_UNIT_TEST)
    message(FATAL_ERROR "Both INTEGRATION_TEST and UNIT_TEST option were specified, you can only specify one")
  elseif(x_INTEGRATION_TEST AND x_VALGRIND_MEMCHECK)
    message(FATAL_ERROR "VALGRIND_MEMCHECK can only be specified with UNIT_TEST")
  endif()

  add_executable(${target} EXCLUDE_FROM_ALL ${x_SRCS})
  set_target_properties(${target} PROPERTIES SWIFT_TYPE "test")
  swift_set_language_standards(${target} C_EXTENSIONS_ON)
  target_code_coverage(${target} AUTO ALL)
  if(x_INCLUDE)
    target_include_directories(${target} PRIVATE ${x_INCLUDE})
  endif()
  if(x_LINK)
    target_link_libraries(${target} PRIVATE ${x_LINK})
  endif()

  if (NOT ${PROJECT_NAME}_BUILD_TESTS)
    return()
  endif()

  swift_create_test_targets()

  add_custom_target(
    do-${target}
    COMMAND ${target}
    ${wd}
    COMMENT "Running ${x_COMMENT}"
  )
  add_dependencies(do-${target} ${target})

  if(x_PARALLEL)
    add_custom_target(parallel-${target}
      COMMAND ${PROJECT_SOURCE_DIR}/third_party/gtest-parallel/gtest-parallel $<TARGET_FILE:${target}>
      ${wd}
      COMMENT "Running ${x_COMMENT} in parallel"
    )
    add_dependencies(parallel-${target} ${target})
  endif()

  add_dependencies(build-all-tests ${target})

  if(x_PARALLEL)
    add_dependencies(do-all-tests parallel-${target})
  else()
    add_dependencies(do-all-tests do-${target})
  endif()

  if (x_INTEGRATION_TEST)
    get_property(targets GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS)
    set_property(GLOBAL PROPERTY SWIFT_INTEGRATION_TEST_TARGETS ${targets} ${target})
    set_target_properties(${target}
      PROPERTIES
        SWIFT_PROJECT ${PROJECT_NAME}
    )

    if (NOT TARGET do-all-integration-tests)
      add_custom_target(do-all-integration-tests)
    endif()

    if(x_PARALLEL)
      add_dependencies(do-all-integration-tests parallel-${target})
    else()
      add_dependencies(do-all-integration-tests do-${target})
    endif()
  endif()

  if (x_UNIT_TEST)
    get_property(targets GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS)
    set_property(GLOBAL PROPERTY SWIFT_UNIT_TEST_TARGETS ${targets} ${target})
    set_target_properties(${target}
      PROPERTIES
        SWIFT_PROJECT ${PROJECT_NAME}
    )

    if (NOT TARGET do-all-unit-tests)
      add_custom_target(do-all-unit-tests)
    endif()

    if(x_PARALLEL)
      add_dependencies(do-all-unit-tests parallel-${target})
    else()
      add_dependencies(do-all-unit-tests do-${target})
    endif()

    if (x_VALGRIND_MEMCHECK)
      include(Valgrind)
      swift_add_valgrind_memcheck(${target}
        LEAK_CHECK full
        ${wd}
        SHOW_REACHABLE
        UNDEF_VALUE_ERRORS
        TRACK_ORIGINS
        CHILD_SILENT_AFTER_FORK
        TRACE_CHILDREN
        GENERATE_JUNIT_REPORT
      )
    endif()
  endif()

  if(x_POST_BUILD)
    add_custom_target(
      post-build-${target}
      COMMAND ${target}
      ${wd}
      COMMENT "Running post build ${x_COMMENT}"
    )
    add_dependencies(do-post-build-tests post-build-${target})
    add_dependencies(build-post-build-tests ${target})
    add_dependencies(post-build-${target} build-post-build-tests)
  endif()
endfunction()
