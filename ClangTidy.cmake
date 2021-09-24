#
# Copyright (C) 2021 Swift Navigation Inc. Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

#
# A module to create custom targets to lint source files using clang-tidy
#
# Call swift_create_clang_tidy_targets at the end of the top level CMakeLists.txt to create targets for running clang-tidy
#
# clang-tidy version 6 must be available on the system for this module to work properly. If an appropriate clang-tidy can't be found no targets will be created and a warning will
# be logged
#
# swift_create_clang_tidy_targets will only have an effect for top level projects. If called within a subproject it will return without taking any action
#
# For every compilable target defined within the calling repository two targets will be created.
#
# The first target 'clang-tidy-${target}' will invoke clang-tidy for all source files which make up the given target. It will export fixes to a file called 'fixes-${target}.yaml'
# in the top level project source directory.
#
# The second target 'clang-tidy-${target}-check' will run clang-tidy as the target described above and then return an error code if any warning/errors were generated
#
# In addition there are two other targets created which lint multiple targets at the same time
#
# clang-tidy-all runs clang-tidy on all "core" targets in the repository (targets which were added with swift_add_executable or swift_add_library)
#
# clang-tidy-world runs clang-tidy on all compilable targets in the repository including all test suites
#
# clang-tidy-all and clang-tidy-world each have a "check" variant which returns an error code should any warning/errors be generated
#
# swift_create_clang_tidy_targets will generate a .clang-tidy file in the project source directory which contains the Swift master config for clang-tidy. There is no need for
# repositories to maintain their own version of .clang-tidy, it should be added to .gitignore in each repository to prevent being checked in.
#

# Helper function to actually create the targets, not to be used outside this file
function(create_clang_tidy_targets key fixes)
  add_custom_target(
    clang-tidy-${key}
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary ${CLANG_TIDY} -p ${CMAKE_BINARY_DIR} -export-fixes=${CMAKE_SOURCE_DIR}/${fixes}
            ${ARGN}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
  add_custom_target(
    clang-tidy-${key}-check
    COMMAND test ! -f ${CMAKE_SOURCE_DIR}/${fixes}
    DEPENDS clang-tidy-${key}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endfunction()

function(swift_create_clang_tidy_targets)
  if(NOT ${CMAKE_PROJECT_NAME} STREQUAL ${PROJECT_NAME})
    return()
  endif()

  # This is required so that clang-tidy can work out what compiler options to use for each file
  set(CMAKE_EXPORT_COMPILE_COMMANDS
      ON
      CACHE BOOL "Export compile commands" FORCE)

  find_program(CLANG_TIDY NAMES clang-tidy-6.0 clang-tidy)

  if("${CLANG_TIDY}" STREQUAL "CLANG_TIDY-NOTFOUND")
    message(WARNING "Could not find clang-tidy, link targets will not be created")
    return()
  endif()

  # By default all clang-tidy are disabled. The following set of suites will be enabled in their entirety
  set(enabled_categories
      # bugprone could probably do with being turned on
      # bugprone*
      cert*
      clang-analyzer*
      cppcoreguidelines*
      google*
      misc*
      modernize*
      performance*
      readability*)

  # The set of specific tests which will be disabled. All checks in this list should have a reason for being disabled placed in a comment along side. Use wildcards with care, in
  # general try to disabled the minimum set of checks required and provide a reason for doing so.
  set(disabled_checks
      # Don't need OSX checks
      -clang-analyzer-osx*
      -clang-analyzer-optin.osx.*
      # Test suites aren't linted
      -clang-analyzer-apiModeling.google.GTest
      # Don't care about LLVM conventions
      -clang-analyzer-llvm.Conventions
      # Function size is not enforced through clang-tidy, sonar cloud has its own check
      -readability-function-size
      # No using MPI
      -clang-analyzer-optin.mpi*
      # No ObjC code anywhere
      -google-objc*
      # clang-format takes care of indentation
      -readability-misleading-indentation
      # Doesn't appear to be functional, even if it were appropriate
      -readability-identifier-naming
      # Caught by compiler, -Wunused-parameter
      -misc-unused-parameters
      # We have a external function blacklist which is much faster, don't need clang to do it
      -clang-analyzer-security.insecureAPI*
      # All the following checks were disabled when the CI project started. They are left like this to avoid having to make too many code changes. This should not be taken as an
      # endorsement of anything.
      -cert-dcl03-c
      -cert-dcl21-cpp
      -cert-err34-c
      -cert-err58-cpp
      -clang-analyzer-alpha*
      -clang-analyzer-core.CallAndMessage
      -clang-analyzer-core.UndefinedBinaryOperatorResult
      -clang-analyzer-core.uninitialized.Assign
      -clang-analyzer-core.uninitialized.UndefReturn
      -clang-analyzer-optin.cplusplus.VirtualCall
      -clang-analyzer-optin.performance.Padding
      -cppcoreguidelines-owning-memory
      -cppcoreguidelines-pro-bounds-array-to-pointer-decay
      -cppcoreguidelines-pro-bounds-constant-array-index
      -cppcoreguidelines-pro-bounds-pointer-arithmetic
      -cppcoreguidelines-pro-type-member-init
      -cppcoreguidelines-pro-type-static-cast-downcast
      -cppcoreguidelines-pro-type-union-access
      -cppcoreguidelines-pro-type-vararg
      -cppcoreguidelines-special-member-functions
      -google-runtime-references
      -misc-static-assert
      -modernize-deprecated-headers
      -modernize-pass-by-value
      -modernize-redundant-void-arg
      -modernize-return-braced-init-list
      -modernize-use-auto
      -modernize-use-bool-literals
      -modernize-use-default-member-init
      -modernize-use-emplace
      -modernize-use-equals-default
      -modernize-use-equals-delete
      -modernize-use-using
      -performance-unnecessary-value-param
      -readability-avoid-const-params-in-decls
      -readability-non-const-parameter
      -readability-redundant-declaration
      -readability-redundant-member-init)

  # Final list of checks to enable/disable
  set(all_checks -* ${enabled_categories} ${disabled_checks})

  # .clang-tidy needs a comma separated list of checks but cmake uses a semicolon as the list separator
  string(REPLACE ";" "," comma_checks "${all_checks}")

  # Generate .clang-tidy in project root dir
  file(WRITE ${CMAKE_SOURCE_DIR}/.clang-tidy "# Automatically generated, do not edit\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "# Enabled checks are generated from SwiftClangTidy.cmake\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "Checks: \"${comma_checks}\"\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "HeaderFilterRegex: '.*'\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "AnalyzeTemporaryDtors: true\n")

  # These two lists will ultimately contain the complete set of source files to pass to the clang-tidy-all and clang-tidy-world targets
  unset(all_abs_srcs)
  unset(world_abs_srcs)

  # Only lint targets created in this repository. Later on we will create 2 targets: clang-tidy-all will lint all "core" targets, executables and libraries clang-tidy-world will
  # lint everything including test suites
  swift_list_compilable_targets(all_targets ONLY_THIS_REPO SWIFT_TYPES "executable" "library")
  swift_list_compilable_targets(world_targets ONLY_THIS_REPO)

  foreach(target IN LISTS world_targets)
    # Build up a list of source files to pass to clang-tidy
    get_target_property(target_srcs ${target} SOURCES)
    get_target_property(target_dir ${target} SOURCE_DIR)
    unset(abs_srcs)
    foreach(file ${target_srcs})
      get_filename_component(abs_file ${file} ABSOLUTE BASE_DIR ${target_dir})
      list(APPEND abs_srcs ${abs_file})
    endforeach()

    create_clang_tidy_targets(${target} fixes-${target}.yaml ${abs_srcs})

    # All targets are included in the world target
    list(APPEND world_abs_srcs ${abs_srcs})

    if(${target} IN_LIST all_targets)
      # Only "core" executables and libraries are included in the all target
      list(APPEND all_abs_srcs ${abs_srcs})
    endif()
  endforeach()

  if(NOT all_abs_srcs)
    message(WARNING "No sources to lint for clang-tidy-all, that doesn't sound right")
  else()
    list(REMOVE_DUPLICATES all_abs_srcs)
    create_clang_tidy_targets(all fixes.yaml ${all_abs_srcs})
  endif()

  if(NOT world_abs_srcs)
    message(WARNING "No sources to lint for clang-tidy-world, that doesn't sound right")
  else()
    list(REMOVE_DUPLICATES world_abs_srcs)
    create_clang_tidy_targets(world fixes.yaml ${world_abs_srcs})
  endif()
endfunction()
