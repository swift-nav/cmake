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

#
# OVERVIEW
# ========
#
# Offers a set of functions which should be replacements for "add_executable"
# and "add_library". Upon including this module, the following functions should
# be available to users:
#
#   * swift_add_executable - defines an executable which is production worthy
#   * swift_add_library - defines a library which is production worthy
#   * swift_add_tool - defines an executable which is an internal tool
#   * swift_add_tool_library - defines a library which is used by internal tools
#   * swift_add_test_library - defines a library which is used by our test libraries
#
# The term "production worthy" means that it complies with the strict standards
# set forth by functions like "swift_set_compile_options" and
# "swift_set_language_standards".
#
# Note that by including this module, the following functions are also
# available for use:
#
#   * swift_add_test
#   * swift_add_test_runner
#
# These functions are defined in "TestTargets.cmake", so please consult that
# module for details on how to use them. Please notes that currently these
# functions although very similar do have different API to the ones expressed
# in this module.
#
# PURPOSE
# =======
#
# The direct usage of "add_executable" and "add_library" has the unfortunate
# drawback of requiring users to call function like "swift_set_compile_options"
# and "swift_set_language_standards" explicitly to impose coding standards on
# new targets. This imposes higher cognitive demand on users and as such can
# lead to them accidentally forgetting to add them and thereby resulting in
# portions of the codebase being less pedantic about coding guidelines.
#
# The usage of "swift_add_*" functions is meant to overcome these issues by:
#
#   * centralizing control over targets
#   * categorizing targets according to different levels of stringent-ness
#   * highlighting which targets are defined by Swift Navigation and which are
#     defined and controlled by third party libraries
#   * target tracking and reporting of compliance
#
# USAGE
# =====
#
# For those that just want to get a quick synopsis of what it takes to use the
# function, lets say we want to create a new library, lets call it "my-lib",
# you can do so via:
#
#   swift_add_library(my-lib SOURCES a.cc b.cc c.cc)
#
# This would be roughly equivalent to:
#
#   add_library(my-lib a.cc b.cc c.cc)
#   swift_set_compile_options(my-lib)
#   swift_set_language_standards(my-lib)
#   target_code_coverage(my-lib NO_RUN)
#
# You can achieve the same with an executable, simply replace "swift_add_library"
# with "swift_add_executable". Note that to create libraries, you can use the
# following function:
#
#   * swift_add_library
#   * swift_add_tool_library
#   * swift_add_test_library
#
# With executables, you can use one of the following:
#
#   * swift_add_executable
#   * swift_add_tool
#
# There are a number of keywords you can use for the functions, they are listed
# below. Just a reminder that when using these keywords, please try and specify
# the multi-value keywords last, this can avoid some of the cmake issues that
# people might stumble upon if they incorrectly spell the keyword.
#
# OPTION KEYWORDS
#
#  INTERFACE: this only works for library targets; it marks the library as an
#  "interface" library (see: "add_library"'s INTERFACE keyword).
#
#  OBJECT: this only works for library targets; it marks the library as an
#  "object" library (see: "add_library"'s OBJECT keyword).
#
#  STATIC|SHARED|MODULE: this only works for library targets; it specifies the
#  type of library, mirrors the exact same options as the "add_library" uses.
#
#  WARNING: normally if the compiler identifies any warnings in the program,
#  it will error the build, by adding this keyword, the target will proceed
#  with the build without failing the build.
#
#  EXCEPTIONS: by default, all targets have C++ exceptions turned off, by
#  adding this keyword, a target can use exceptions.
#
#  RTTI: by default, all targets will have C++ RTTI (run time type information)
#  disabled, by adding this keyword it enables RTTI on the target.
#
#  C_EXTENSIONS_ON: C extensions are disabled by default, adding this keyword
#  enables C extensions.
#
#  SKIP_COMPILE_OPTIONS: will forgo invoking the swift_set_compile_options on
#  the target.
#
# SINGLE VALUE KEYWORDS
#
#  C_STANDARD: allow uses to override the default C standard used in a target,
#  see https://cmake.org/cmake/help/latest/prop_tgt/C_STANDARD.html for the
#  list of possible values.
#
#  CXX_STANDARD: allow uses to override the default C++ standard used in a
#  target, see https://cmake.org/cmake/help/latest/prop_tgt/CXX_STANDARD.html
#  for the list of possible values.
#
# MULTI VALUE KEYWORDS
#
#  SOURCES: lists out the sources for a particular target. if one uses the
#  INTERFACE keyword, one must not specify this keyword as well.
#
#  ADD_COMPILE_OPTIONS: allows users to specify compile options on a target
#
#  REMOVE_COMPILE_OPTIONS: allows users to remove the default compile options
#  that are enabled by "swift_set_compile_options" (see "CompileOptions.cmake"
#  for details).
#
# At the end of the top level CMakeLists.txt for a repository call
# swift_validate_targets. The function performs validation on all defined targets
# to make sure they have been defined according to Swift policies. Currently
# this only checks to make sure that all compilable targets were created with a
# swift_add_* function (instead of built in add_* functions).
#

include(CodeCoverage)
include(CompileOptions)
include(LanguageStandards)
include(TestTargets)
include(ListTargets)

cmake_policy(SET CMP0007 NEW)  # new behaviour list command no longer ignores empty elements

define_property(TARGET
  PROPERTY SWIFT_TYPE
  BRIEF_DOCS "Swift target type"
  FULL_DOCS "For use by other modules in this repository which need to know the classification of target. One of executable, library, tool, tool_library, test, test_library")

define_property(TARGET
  PROPERTY INTERFACE_SWIFT_TYPE
  BRIEF_DOCS "Swift target type"
  FULL_DOCS "Identical use as SWIFT_TYPE except that this applies to ALL target types, including INTERFACE")

define_property(TARGET
  PROPERTY SWIFT_PROJECT
  BRIEF_DOCS "Swift project name"
  FULL_DOCS "For use by other modules in this repository which need to know the project which this target belongs to")

define_property(TARGET
  PROPERTY INTERFACE_SWIFT_PROJECT
  BRIEF_DOCS "Swift project name"
  FULL_DOCS "Identical use as SWIFT_PROJECT except that this applies to ALL target types, including INTERFACE")

define_property(TARGET
  PROPERTY SWIFT_TEST_TYPE
  BRIEF_DOCS "Swift test type"
  FULL_DOCS "When target's SWIFT_PROJECT property is \"test\", this option, if set, will identify what type of test it is. Currently support \"unit\" or \"integration\"")

define_property(TARGET
  PROPERTY INTERFACE_SOURCE_DIR
  BRIEF_DOCS "Target's source directory"
  FULL_DOCS "Identical use as SOURCE_DIR except that this applies to ALL target types, including INTERFACE")

macro(swift_collate_arguments prefix name)
  set(exclusion_list ${ARGN})
  set(${name}_args "")

  foreach(arg IN LISTS ${name}_option)
    list(FIND exclusion_list "${arg}" index)
    if (NOT index EQUAL -1)
      continue()
    endif()
    if (${prefix}_${arg})
      list(APPEND ${name}_args ${arg})
    endif()
  endforeach()

  foreach(arg IN LISTS ${name}_single ${name}_multi)
    list(FIND exclusion_list "${arg}" index)
    if (NOT index EQUAL -1)
      continue()
    endif()
    if (${prefix}_${arg})
      list(APPEND ${name}_args ${arg} ${${prefix}_${arg}})
    endif()
  endforeach()
endmacro()

function(swift_add_target target type)
  set(this_option INTERFACE OBJECT STATIC SHARED MODULE SKIP_COMPILE_OPTIONS)
  set(this_single "")
  set(this_multi SOURCES)

  set(compile_options_option WARNING NO_EXCEPTIONS EXCEPTIONS NO_RTTI RTTI)
  set(compile_options_single "")
  set(compile_options_multi ADD_COMPILE_OPTIONS REMOVE_COMPILE_OPTIONS)

  set(language_standards_option C_EXTENSIONS_ON)
  set(language_standards_single C_STANDARD CXX_STANDARD)
  set(language_standards_multi "")

  set(arg_option ${this_option} ${compile_options_option} ${language_standards_option})
  set(arg_single ${this_single} ${compile_options_single} ${language_standards_single})
  set(arg_multi ${this_multi} ${compile_options_multi} ${language_standards_multi})
  list(REMOVE_ITEM arg_option "")
  list(REMOVE_ITEM arg_single "")
  list(REMOVE_ITEM arg_multi "")

  cmake_parse_arguments(x "${arg_option}" "${arg_single}" "${arg_multi}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  swift_collate_arguments(x compile_options ADD_COMPILE_OPTIONS REMOVE_COMPILE_OPTIONS)
  swift_collate_arguments(x language_standards C_STANDARD CXX_STANDARD)

  if (x_ADD_COMPILE_OPTIONS)
    list(APPEND compile_options_args ADD ${x_ADD_COMPILE_OPTIONS})
  endif()
  if (x_REMOVE_COMPILE_OPTIONS)
    list(APPEND compile_options_args REMOVE ${x_REMOVE_COMPILE_OPTIONS})
  endif()

  if (x_C_STANDARD)
    list(APPEND language_standards_args C ${x_C_STANDARD})
  endif()
  if (x_CXX_STANDARD)
    list(APPEND language_standards_args CXX ${x_CXX_STANDARD})
  endif()

  if (x_INTERFACE AND x_OBJECT)
    message(FATAL_ERROR "Can't specify both INTERFACE and OBJECT when defining a target")
  endif()

  if (x_INTERFACE)
    if (x_SOURCES)
      message(FATAL_ERROR "Can't create interface target with source files")
    endif()
    if (x_STATIC OR x_SHARED OR x_MODULE)
      message(FATAL_ERROR "Can't create interface target with a specified library type (STATIC/SHARED/MODULE)")
    endif()
  endif()

  if (x_OBJECT AND (x_STATIC OR x_SHARED OR x_MODULE))
    message(FATAL_ERROR "Can't create object target with a specified library type (STATIC/SHARED/MODULE)")
  endif()

  set(extra_flags)
  set(library_type)

  if (x_STATIC)
    list(APPEND library_type STATIC)
  endif()
  if (x_SHARED)
    list(APPEND library_type SHARED)
  endif()
  if (x_MODULE)
    list(APPEND library_type MODULE)
  endif()

  if (type STREQUAL "executable")
    add_executable(${target} ${x_SOURCES})
    list(APPEND extra_flags -pedantic)
  elseif(type STREQUAL "library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    elseif(x_OBJECT)
      add_library(${target} OBJECT ${x_SOURCES})
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
    list(APPEND extra_flags -pedantic)
  elseif(type STREQUAL "test_library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    elseif(x_OBJECT)
      add_library(${target} OBJECT ${x_SOURCES})
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
  elseif(type STREQUAL "tool")
    add_executable(${target} ${x_SOURCES})
  elseif(type STREQUAL "tool_library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    elseif(x_OBJECT)
      add_library(${target} OBJECT ${x_SOURCES})
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
  else()
    message(FATAL_ERROR "Unknown Swift target type ${type}")
  endif()

  #
  # This edge case is needed for cmake version < 3.19.0 where INTERFACE
  # classes cannot contain any property other than those prefixed with
  # "INTERFACE_".
  #
  # see: https://stackoverflow.com/questions/68502038/custom-properties-for-interface-libraries
  #
  # Until we migrate the cmake scripts to require 3.19.0, we should use the
  # "INTERFACE_*" properties. If you want to go the extra mile, make sure to
  # check both `INTERFACE_` and non `INTERFACE_` properties, later on we can
  # delete the `INTERFACE_` once this illogical constraint is removed.
  #
  set_target_properties(${target}
    PROPERTIES
      INTERFACE_SWIFT_PROJECT ${PROJECT_NAME}
      INTERFACE_SWIFT_TYPE ${type}
      INTERFACE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  )

  if (NOT x_INTERFACE)
    set_target_properties(${target}
      PROPERTIES
        SWIFT_PROJECT ${PROJECT_NAME}
        SWIFT_TYPE ${type}
    )

    swift_set_language_standards(${target} ${language_standards_args})
    target_code_coverage(${target} NO_RUN)

    if (NOT x_SKIP_COMPILE_OPTIONS)
      swift_set_compile_options(${target} ${compile_options_args} EXTRA_FLAGS ${extra_flags})
    endif()
  endif()
endfunction()

function(swift_add_executable target)
  swift_add_target("${target}" executable ${ARGN})
endfunction()

function(swift_add_tool target)
  swift_add_target("${target}" tool ${ARGN})
endfunction()

function(swift_add_tool_library target)
  swift_add_target("${target}" tool_library ${ARGN})
endfunction()

function(swift_add_library target)
  swift_add_target("${target}" library ${ARGN})
endfunction()

function(swift_add_test_library target)
  swift_add_target("${target}" test_library ${ARGN})
endfunction()

function(swift_validate_targets)
  swift_list_compilable_targets(all_targets ONLY_THIS_REPO SWIFT_TYPES "executable" "library")

  foreach(target ${all_targets})
    get_target_property(swift_type ${target} SWIFT_TYPE)
    if(NOT swift_type)
      message(FATAL_ERROR "Can't identify type of target ${target}, was it added with the correct Swift function (swift_add_*)?")
    endif()
  endforeach()
endfunction()
