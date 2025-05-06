#
# Copyright (C) 2021 Swift Navigation Inc. Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

#
# A helper module to enumerate all targets created in a source tree
#
# Calling swift_list_targets will populate the given variable with the list of targets which meet the given criteria. It will report all targets created in the current source dir
# and all of its subdirectories
#
# Use the ONLY_THIS_REPO option to exclude targets which were created in submodules, returns a list of targets which were created in the caller's repository. This is fairly dumb
# test which simply looks for 'third_party' anywhere in the path of the candidate target and excludes it
#
# Use the TYPES option to filter the returned list of targets based on the cmake target type (EXECUTABLE, DYNAMIC_LIBRARY and so on). Only targets which match one of the entries
# in this list will be returned
#
# Use the SWIFT_TYPES option to filter the returned list of targets based on the Swift target type. This should be a list of target types which match one of the 'swift_add_*'
# functions from SwiftTargets.cmake and TestTargets.cmake (ie, "executable", "library", "test", and so on)
#
# Example usage:
#
# Populate 'interfaces' with the set of interface library targets created within this repository
#
# swift_list_targets(interfaces ONLY_THIS_REPO TYPES "INTERFACE")
#
# Populate 'all_tests' with the set of tests defined anywhere within the source tree under the calling function's directory
#
# swift_list_targets(all_tests SWIFT_TYPE "test")
#
# A helper function swift_list_compilable_targets is provided which is equivalent to calling swift_list_targets with the option "TYPES EXECUTABLE DYNAMIC_LIBRARY STATIC_LIBRARY
# OBJECT_LIBRARY", ie the set of all targets which can be compiled (not interface libraries). Other options can be passed in to this function (ONLY_THIS_REPO, SWIFT_TYPES) as for
# swift_list_targets
#

cmake_minimum_required(VERSION 3.13)

function(get_all_targets result dir)
  get_property(
    subdirs
    DIRECTORY "${dir}"
    PROPERTY SUBDIRECTORIES)
  foreach(subdir IN LISTS subdirs)
    get_all_targets(${result} "${subdir}")
  endforeach()

  get_directory_property(sub_targets DIRECTORY "${dir}" BUILDSYSTEM_TARGETS)
  set(${result}
      ${${result}} ${sub_targets}
      PARENT_SCOPE)
endfunction()

function(swift_list_targets out_var)
  set(argOption "ONLY_THIS_REPO")
  set(argSingle "")
  set(argMulti "TYPES" "SWIFT_TYPES")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments to swift_list_targets ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(x_all_targets)
  get_all_targets(x_all_targets ${CMAKE_CURRENT_SOURCE_DIR})

  set(all_targets)

  foreach(target IN LISTS x_all_targets)
    get_target_property(type ${target} TYPE)
    if(x_TYPES)
      if(NOT ${type} IN_LIST x_TYPES)
        continue()
      endif()
    endif()

    if(x_SWIFT_TYPES)
      if (type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(swift_type ${target} INTERFACE_SWIFT_TYPE)
      else()
        get_target_property(swift_type ${target} SWIFT_TYPE)
      endif()

      if(NOT ${swift_type} IN_LIST x_SWIFT_TYPES)
        continue()
      endif()
    endif()

    if(x_ONLY_THIS_REPO)
      if (type STREQUAL "INTERFACE_LIBRARY")
        get_target_property(target_dir ${target} INTERFACE_SOURCE_DIR)
      else()
        get_target_property(target_dir ${target} SOURCE_DIR)
      endif()

      # This replacement makes sure that we only filter out third_party subdirectories which actually exist in the root project source dir - ie, a git repo cloned in to a path
      # which just so happens to contain third_party should not break this function
      string(REPLACE ${CMAKE_SOURCE_DIR} "" target_dir ${target_dir})
      if(${target_dir} MATCHES ".*third_party.*")
        continue()
      endif()
    endif()

    set(all_targets ${all_targets} ${target})
  endforeach()

  set(${out_var}
      ${all_targets}
      PARENT_SCOPE)
endfunction()

function(swift_list_compilable_targets out_var)
  swift_list_targets(
    ${out_var}
    TYPES
    "EXECUTABLE"
    "MODULE_LIBRARY"
    "SHARED_LIBRARY"
    "STATIC_LIBRARY"
    "OBJECT_LIBRARY"
    ${ARGN})
  set(${out_var}
      ${${out_var}}
      PARENT_SCOPE)
endfunction()
