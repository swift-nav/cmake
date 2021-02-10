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
#
# LINK, INCLUDE, and WORKING_DIRECTORY are optional parameters. 
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
# target which pointer at some other command. This can be used to invoke a test 
# which is actually a shell script or some other executable which is available 
# but not built from source
#
# swift_add_test_runner(test-suite-name
#    COMMAND <testing command> <arguments>
#    WORKING_DIRECTORY <path>
#    DEPENDS <optional list of cmake targets on which this test depend>
#    )
#
# This will create just a single target:
# - do-test-suite-name - Execute the given command
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
# - do-all-tests - Execute all specified tests
#

include(LanguageStandards)
include(CodeCoverage)

macro(swift_create_test_targets)
if(NOT TARGET build-all-tests)
  add_custom_target(build-all-tests)
endif()

if(NOT TARGET do-all-tests)
  add_custom_target(do-all-tests)
endif()
endmacro()

function(swift_add_test_runner target)
  set(argOption "POST_BUILD")
  set(argSingle "COMMENT" "WORKING_DIRECTORY")
  set(argMulti "COMMAND" "DEPENDS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test_runner unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  swift_create_test_targets()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  if(x_WORKING_DIRECTORY)
    set(wd WORKING_DIRECTORY ${x_WORKING_DIRECTORY})
  endif()

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

  if(x_POST_BUILD)
    message(WARNING "Marking tests as POST_BUILD has been deprecated, tests will no longer run as part of `make all`. This test can be run individually with `make do-${target}`, or `make do-all-tests` can be used to run all registered tests")
  endif()
endfunction()

function(swift_add_test target)
  set(argOption "PARALLEL" "POST_BUILD")
  set(argSingle "COMMENT" "WORKING_DIRECTORY")
  set(argMulti "SRCS" "LINK" "INCLUDE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  swift_create_test_targets()

  if(NOT x_SRCS)
    message(FATAL_ERROR "swift_add_test must be passed at least one source file")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  if(x_WORKING_DIRECTORY)
    set(wd WORKING_DIRECTORY ${x_WORKING_DIRECTORY})
  endif()

  add_executable(${target} EXCLUDE_FROM_ALL ${x_SRCS})
  swift_set_language_standards(${target})
  if(x_INCLUDE)
    target_include_directories(${target} PRIVATE ${x_INCLUDE})
  endif()
  if(x_LINK)
    target_link_libraries(${target} PRIVATE ${x_LINK})
  endif()

  add_custom_target(
      do-${target}
      COMMAND ${target}
      ${wd}
      COMMENT "Running ${x_COMMENT}"
      )
  add_dependencies(do-${target} ${target})
  target_code_coverage(${target} AUTO ALL)

  if(x_PARALLEL)
    add_custom_target(parallel-${target}
        COMMAND ${PROJECT_SOURCE_DIR}/third_party/gtest-parallel/gtest-parallel $<TARGET_FILE:${target}>
        ${wd}
        COMMENT "Running ${x_COMMENT} in parallel"
        )
    add_dependencies(parallel-${target} ${target})
  endif()

  add_dependencies(build-all-tests ${target})
  add_dependencies(do-all-tests do-${target})

  if(x_POST_BUILD)
    message(WARNING "Marking tests as POST_BUILD has been deprecated, tests will no longer run as part of `make all`. This test can be run individually with `make do-${target}`, or `make do-all-tests` can be used to run all registered tests")
  endif()
endfunction()
