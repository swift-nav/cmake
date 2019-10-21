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
#    )
#
# This will create 2 cmake targets
# - test-suite-name - an executable composed of the specified source files, 
#   linked against the specified libraries
# - do-test-suite-name - A custom target which will execute the above target
#
#
# LINK and INCLUDE are optional parameters. 
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
#    COMMAND <shell-command-to-run-test>
#    DEPENDS <optional list of cmake targets on which this test depend>
#    )
#
# This will create just a single target:
# - do-test-suite-name - Execute the given command
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

option(AUTORUN_TESTS "" ON)
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

function(swift_add_test_runner target)
  set(argOption "POST_BUILD")
  set(argSingle "COMMENT")
  set(argMulti "COMMAND" "DEPENDS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  add_custom_target(
      do-${target}
      COMMAND ${x_COMMAND}
      COMMENT "Running ${x_COMMENT}"
      )
  add_dependencies(do-all-tests do-${target})
  if(x_DEPENDS)
    add_dependencies(do-${target} ${x_DEPENDS})
  endif()

  if(x_POST_BUILD)
    add_custom_target(post-build-${target}
        COMMAND ${x_COMMAND}
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
  set(argOption "PARALLEL" "POST_BUILD")
  set(argSingle "COMMENT")
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
      COMMENT "Running ${x_COMMENT}"
      )
  add_dependencies(do-${target} ${target})
  target_code_coverage(${target} AUTO ALL)

  if(x_PARALLEL)
    add_custom_target(parallel-${target}
        COMMAND ${PROJECT_SOURCE_DIR}/third_party/gtest-parallel/gtest-parallel $<TARGET_FILE:${target}>
        COMMENT "Running ${x_COMMENT} in parallel"
        )
    add_dependencies(parallel-${target} ${target})
  endif()

  add_dependencies(build-all-tests ${target})
  add_dependencies(do-all-tests do-${target})

  if(x_POST_BUILD)
    add_custom_target(
        post-build-${target}
        COMMAND ${target}
        COMMENT "Running post build ${x_COMMENT}"
        )
    add_dependencies(do-post-build-tests post-build-${target})
    add_dependencies(build-post-build-tests ${target})
    add_dependencies(post-build-${target} build-post-build-tests)
  endif()
endfunction()
