# Standard options for Swift cmake based project
#
# This module sets up cmake options for whatever features a project has.
# Supports the following features:
#
# - Tests
# - Test libraries for use by other projects
# - Documentation
# - Examples
#
# CMake options are set up with the names
# - {project_name}_ENABLE_{feature}
#
# For example:
# - libsbp_ENABLE_TESTS
# - albatross_ENABLE_EXAMPLES
#
# Options are enabled by default but can be set on the command line at 
# configure time, eg
#
# cmake -Dlibsbp_ENABLE_TESTS=OFF <path>
#
# They can also be disabled in CMakeLists.txt in a superproject, eg.
#
# ...
# option(libsbp_ENABLE_TESTS "" OFF)
# find_package(libsbp)
# ...
#
# Usage:
# Import this module and call the function swift_create_project_options 
# specifying what features are available in the package. eg
#
# project(libsbp)
# include(SwiftCmakeOptions)
# swift_create_project_options(HAS_TESTS HAS_DOCS)
#
# Test components.
# The TEST and TEST_LIBS features have some extra processing. They will
# be automatically disabled when cross compiling, regardless of whether
# they are explicitly enabled or not. This behaviour can be disabled
# by passing the option SKIP_CROSS_COMPILING_CHECK. For example
#
# swift_create_project_options(HAS_TESTS SKIP_CROSS_COMPILING_CHECK)
#
# will enable unit tests and test libraries even when cross compiling.
#
# Conversely, the option DISABLE_TEST_COMPONENTS can be used to force
# unit tests and test libraries to always be disabled, ignore any user
# preference. For example
#
# swift_create_project_options(HAS_TESTS DISABLE_TEST_COMPONENTS TRUE)
#
# will disable unit tests and test libraries even if the user has
# requested them. This is useful so a project can disable test components
# based on other conditions that this module is not aware of, such as
# when using a particular compiler. The following example will always
# disable test components when using the Visual Studio compiler
#
# set(disable_tests FALSE)
# if(MSVC)
#   set(disable_tests TRUE)
# endif()
# swift_create_project_options(HAS_TESTS DISABLE_TEST_COMPONENTS ${disable_tests})
#
# A list of dependencies for test components can be specified using the 
# TEST_PACKAGES option. Pass a list of packages which will be searched for
# using the find_package() cmake function. If any of the packages is not
# found the unit tests will be disabled
#
# swift_create_project_options(HAS_TESTS TEST_PACKAGES "Googletest" "RapidCheck")
#
# Similarly, the TEST_LIBS_PACKAGES can be used to specify the dependencies
# of the test libraries. If takes the same behaviour as the TEST_PACKAGES library
# except it will only disable the test libraries feature if requirements are not
# met. If this option is not specified it assumes the same value as TEST_PACKAGES
#
# The following test packages are currently supported:
#
# - Googletest (targets gtest etc)
# - RapidCheck
# - GFlags
# - Json
# - Yaml-Cpp
# - FastCSV
#
# Finally, this function will use the current project name as a prefix
# to all options and output variables. This can be overridden by
# passing the PROJECT option
#
# swift_create_project_options(PROJECT test_project HAS_TESTS)
#
# will create an option called test_project_ENABLE_TESTS
#
# After processing this function sets several cache variables which can
# be used elsewhere to determine which targets to compile. The output
# cache variable name is in the form {project}_BUILD_{feature}. eg
#
# libsbp_BUILD_TESTS
# albatross_BUILD_EXAMPLES
#
# This can be used in CMakeLists.txt to selective compile targets eg.
#
# if(libsbp_BUILD_TESTS)
#   add_executable(libsbp-test <sources>)
# endif()
#
# or include subdirectories
#
# if(albatross_BUILD_EXAMPLES)
#   add_subdirectory(examples)
# endif()
#
# or any other valid cmake construct.
#

function(verify_test_dependencies)
  cmake_parse_arguments(x "" "" "TEST_PACKAGES" ${ARGN})

  set(dependencies_available ON PARENT_SCOPE)
  if(x_TEST_PACKAGES)
    foreach(P ${x_TEST_PACKAGES})
      find_package(${P})
      # Annoyingly, different test packages have different ways of reporting they were found
      set(found FALSE)
      if(${P} STREQUAL "Check" AND CHECK_FOUND)
        set(found TRUE)
      elseif(${P} STREQUAL "Googletest" AND TARGET gtest)
        set(found TRUE)
      elseif(${P} STREQUAL "RapidCheck" AND TARGET rapidcheck)
        set(found TRUE)
      elseif(${P} STREQUAL "GFlags" AND TARGET gflags)
        set(found TRUE)
      elseif(${P} STREQUAL "Json" AND TARGET nlohmann_json)
        set(found TRUE)
      elseif(${P} STREQUAL "Yaml-Cpp" AND TARGET yaml-cpp)
        set(found TRUE)
      elseif(${P} STREQUAL "FastCSV" AND TARGET fast-csv)
        set(found TRUE)
      endif()
      if(NOT found)
        message(STATUS "Disable tests because dependency ${P} was not found")
        set(dependencies_available OFF PARENT_SCOPE)
      endif()
    endforeach()
  endif()
endfunction()


function(swift_create_project_options)
  set(argOptions "HAS_TESTS" "HAS_TEST_LIBS" "HAS_DOCS" "HAS_EXAMPLES" "SKIP_CROSS_COMPILING_CHECK")
  set(argSingleArguments "PROJECT" "DISABLE_TEST_COMPONENTS")
  set(argMultiArguments "TEST_PACKAGES" "TEST_LIBS_PACKAGES")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in swift_create_project_options: ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_PROJECT)
    set(x_PROJECT ${PROJECT_NAME})
  endif()

  set(tests_possible ON)
  set(test_libs_possible ON)
  if(x_DISABLE_TEST_COMPONENTS)
    message(STATUS "Test components disabled by project")
    set(tests_possible OFF)
    set(test_libs_possible OFF)
  endif()

  if(NOT x_SKIP_CROSS_COMPILING_CHECK)
    if(CMAKE_CROSSCOMPILING)
      # Don't compile any test stuff if we are cross compiling
      message(STATUS "Skipping unit tests because we are cross compiling")
      set(tests_possible OFF)
      set(test_libs_possible OFF)
    endif()
  endif()

  set(build_tests FALSE)
  set(build_test_libs FALSE)

  if(x_HAS_TESTS)
    option(${x_PROJECT}_ENABLE_TESTS "Enable build of unit tests for ${x_PROJECT}" ${tests_possible})
    if(${x_PROJECT}_ENABLE_TESTS)
      if(tests_possible)
        set(build_tests TRUE)
      endif()
    endif()
  endif()

  if(x_HAS_TEST_LIBS)
    option(${x_PROJECT}_ENABLE_TEST_LIBS "Enable build of test libraries for ${x_PROJECT}" ${test_libs_possible})
    if(${x_PROJECT}_ENABLE_TEST_LIBS)
      if(test_libs_possible)
        set(build_test_libs TRUE)
      endif()
    endif()
  endif()

  if(build_tests)
    verify_test_dependencies(TEST_PACKAGES ${x_TEST_PACKAGES})

    if(NOT dependencies_available)
      set(build_tests OFF)
    endif()
  endif()

  if(build_test_libs)
    if(x_TEST_LIBS_PACKAGES)
      verify_test_dependencies(TEST_PACKAGES ${x_TEST_LIBS_PACKAGES})
    else()
      verify_test_dependencies(TEST_PACKAGES ${x_TEST_PACKAGES})
    endif()

    if(NOT dependencies_available)
      set(build_test_libs OFF)
    endif()
  endif()

  if(x_HAS_TESTS)
    if(build_tests)
      set(${x_PROJECT}_BUILD_TESTS TRUE CACHE BOOL "Build unit tests for ${x_PROJECT}")
    else()
      message(STATUS "${x_PROJECT} unit tests are DISABLED")
    endif()
  endif()

  if(x_HAS_TEST_LIBS)
    if(build_test_libs)
      set(${x_PROJECT}_BUILD_TEST_LIBS TRUE CACHE BOOL "Build test libraries for ${x_PROJECT}")
    else()
      message(STATUS "${x_PROJECT} test libraries are DISABLED")
    endif()
  endif()

  if(x_HAS_DOCS)
    option(${x_PROJECT}_ENABLE_DOCS "Enable build of documentation for ${x_PROJECT}" ON)
    set(${x_PROJECT}_BUILD_DOCS ${${x_PROJECT}_ENABLE_DOCS} CACHE BOOL "Build documentation for ${x_PROJECT}")
    if(NOT ${x_PROJECT}_BUILD_DOCS)
      message(STATUS "${x_PROJECT} documentation is DISABLED")
    endif()
  endif()

  if(x_HAS_EXAMPLES)
    option(${x_PROJECT}_ENABLE_EXAMPLES "Enable build of example code for ${x_PROJECT}" ON)
    set(${x_PROJECT}_BUILD_EXAMPLES ${${x_PROJECT}_ENABLE_EXAMPLES} CACHE BOOL "Build examples for ${x_PROJECT}")
    if(NOT ${x_PROJECT}_BUILD_EXAMPLES)
      message(STATUS "${x_PROJECT} examples are DISABLED")
    endif()
  endif()

  foreach(feat "TESTS" "TEST_LIBS" "DOCS" "EXAMPLES")
    if(DEFINED ${x_PROJECT}_ENABLE_${feat} AND NOT x_HAS_${feat})
      message(WARNING "${x_PROJECT}_ENABLE_${feat} is set but the package does not support it")
    endif()
  endforeach()

endfunction()
  
