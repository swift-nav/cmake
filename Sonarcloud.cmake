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

#
# OVERVIEW
# ========
#
# Offers a way to generate the necessary Sonarcloud project file from the
# information available via cmake build system. User can call on
# "generate_sonarcloud_project_properties" to produce this project file which
# outlines to Sonarcloud what files/directories are deemed source files and
# which files are test files.
#
# This module will work in conjunction with "TestTargets" and "SwiftTargets",
# and "ListTargets" to identify all Swift production source/test code through.
# This means that only targets created via "swift_add_*" functions that are
# categorized as "production" code will be included in the analysis. No other
# none C/C++ source code will be included in the Sonarcloud project properties
# file (at the moment).
#
# USAGE
# =====
#
# To generate the Sonarcloud project file, simply call the following method at
# the end of your projects CMakeLists.txt file:
#
#   generate_sonarcloud_project_properties(${CMAKE_BINARY_DIR}/sonar-project.properties)
#
# This will generate a sonar project file in your root build directory (please
# don't ever write this to your source directory). Prior to uploading the
# results to Sonarcloud, you will need to manually transform all absolute path
# references to relative paths. This manual step can be done easily with the
# following Linux command:
#
#   sed -i -E "s|^(\s+)(${PWD}/)|\1|g" 'sonar-project.properties'
#
# The reason why this extra step is required and was not taken care by cmake,
# is because targets have generator expressions to them which can only be
# evaluated at the end of the configuration stage. At that point there is no
# find/replace functionality.
#

include(ListTargets)

set(_sonarcloud_newline "\\\n  ")

function(_transform_sonarcloud_source_files output_variable target)
  #
  # Based off of https://cmake.org/cmake/help/latest/prop_tgt/SOURCES.html we
  # need to correctly interpret the SOURCES properties to be able to transform
  # them into what sonarcloud project properties is comfortable with (ie.
  # relative path from project source directory).
  #
  get_target_property(target_binary_dir ${target} BUILD_DIR)
  get_target_property(target_source_dir ${target} SOURCE_DIR)

  unset(source_files)
  foreach (source_file IN LISTS ARGN)
    get_source_file_property(is_build_generated_file ${target_binary_dir}/${source_file} GENERATED)

    if(IS_ABSOLUTE ${source_file})
      list(APPEND source_files ${source_file})
      continue()
    endif()

    if (is_build_generated_file)
      list(APPEND source_files ${target_binary_dir}/${source_file})
      continue()
    endif()

    if (EXISTS ${target_source_dir}/${source_file})
      list(APPEND source_files ${target_source_dir}/${source_file})
      continue()
    endif()

    if (source_file MATCHES "^\\$<.+>$")
      list(APPEND source_files "$<$<BOOL:${source_file}>:$<JOIN:${source_file},$<COMMA>${_sonarcloud_newline}>>")
      continue()
    endif()

    message(WARNING "Sonarcloud is missing source file \"${source_file}\" for target ${target}")
  endforeach()

  set(${output_variable} ${source_files} PARENT_SCOPE)
endfunction()

function(_transform_sonarcloud_include_directories output_variable target)
  unset(include_directories)

  foreach (include_directory IN LISTS ARGN)
    if(IS_ABSOLUTE ${include_directory})
      list(APPEND include_directories ${include_directory})
      continue()
    endif()

    if (include_directory MATCHES "^\\$<INSTALL_INTERFACE:.+>$")
      # ignoring installation interfaces
      continue()
    endif()

    if (include_directory MATCHES "^\\$<.+>$")
      list(APPEND include_directories "$<$<BOOL:${include_directory}>:$<JOIN:${include_directory},$<COMMA>${_sonarcloud_newline}>>")
      continue()
    endif()

    message(WARNING "Sonarcloud is missing include directory \"${include_directory}\" for target ${target}")
  endforeach()

  set(${output_variable} ${include_directories} PARENT_SCOPE)
endfunction()

function(_extract_sonarcloud_project_files output_project_source_files output_project_include_directories)
  unset(project_source_files)
  unset(project_include_directories)

  foreach (target IN LISTS ARGN)
    get_target_property(target_type ${target} TYPE)

    unset(target_source_files)
    unset(target_include_directories)

    if (NOT target_type STREQUAL "INTERFACE_LIBRARY")
      get_target_property(target_source_files ${target} SOURCES)
      if (target_source_files)
        _transform_sonarcloud_source_files(target_source_files ${target} ${target_source_files})
      else()
        unset(target_source_files)
      endif()

      get_target_property(target_include_directories ${target} INCLUDE_DIRECTORIES)
      if (target_include_directories)
        _transform_sonarcloud_include_directories(target_include_directories ${target} ${target_include_directories})
      else()
        unset(target_include_directories)
      endif()
    endif()

    get_target_property(target_interface_include_directories ${target} INTERFACE_INCLUDE_DIRECTORIES)
    if (target_interface_include_directories)
      _transform_sonarcloud_include_directories(target_interface_include_directories ${target} ${target_interface_include_directories})
    else()
      unset(target_interface_include_directories)
    endif()

    list(APPEND project_source_files ${target_source_files})
    list(APPEND project_include_directories ${target_include_directories})
    list(APPEND project_include_directories ${target_interface_include_directories})
  endforeach()

  if (project_source_files)
    list(SORT project_source_files)
    list(REMOVE_DUPLICATES project_source_files)
  endif()

  if (project_include_directories)
    list(SORT project_include_directories)
    list(REMOVE_DUPLICATES project_include_directories)
  endif()

  set(${output_project_source_files} ${project_source_files} PARENT_SCOPE)
  set(${output_project_include_directories} ${project_include_directories} PARENT_SCOPE)
endfunction()

function(generate_sonarcloud_project_properties sonarcloud_project_properties_path)
  if (NOT IS_ABSOLUTE ${sonarcloud_project_properties_path})
    message(FATAL_ERROR "Function \"generate_sonarcloud_project_properties\""
           "only accepts absolute paths to avoid ambiguity")
  endif()

  if (NOT ${PROJECT_SOURCE_DIR} STREQUAL ${CMAKE_SOURCE_DIR})
    return()
  endif()

  swift_list_targets(swift_source_targets
    ONLY_THIS_REPO
    SWIFT_TYPES
      executable
      library
  )
  swift_list_targets(source_targets
    ONLY_THIS_REPO
    TYPES
      EXECUTABLE
      MODULE_LIBRARY
      SHARED_LIBRARY
      STATIC_LIBRARY
      OBJECT_LIBRARY
  )

  list(APPEND source_targets ${swift_source_targets})
  list(REMOVE_DUPLICATES source_targets)

  swift_list_targets(test_targets
    ONLY_THIS_REPO
    SWIFT_TYPES
      test
      test_library
  )

  foreach(test_target ${test_targets})
    list(REMOVE_ITEM source_targets ${test_target})
  endforeach()

  foreach(source_target ${source_targets})
    get_target_property(target_type ${target} TYPE)
    if (NOT target_type STREQUAL "INTERFACE_LIBRARY")
      get_target_property(link_libs ${source_target} LINK_LIBRARIES)
      if("gtest" IN_LIST link_libs)
        list(REMOVE_ITEM source_targets ${source_target})
      endif()
    endif()
  endforeach()

  _extract_sonarcloud_project_files(source_source_files source_include_directories ${source_targets})
  _extract_sonarcloud_project_files(test_source_files test_include_directories ${test_targets})

  set(sonarcloud_project_properties_content "sonar.sourceEncoding=UTF-8\n")

  set(source_files ${source_source_files} ${source_include_directories} ${test_source_files})
  foreach (dir ${source_include_directories})
    set(source_files ${source_files} ${dir}/*.h ${dir}/**/*.h)
  endforeach()
  list(JOIN source_files ",${_sonarcloud_newline}" sonar_sources)
  string(APPEND sonarcloud_project_properties_content "sonar.inclusions=${_sonarcloud_newline}${sonar_sources}\n")

  set(test_files ${test_source_files})
  foreach(source_file ${source_source_files})
    list(REMOVE_ITEM test_files ${source_file})
  endforeach()
  list(JOIN test_files ",${_sonarcloud_newline}" sonar_test_files)
  string(APPEND sonarcloud_project_properties_content "sonar.coverage.exclusions=${_sonarcloud_newline}${sonar_test_files}\n")

  file(GENERATE
    OUTPUT "${sonarcloud_project_properties_path}"
    CONTENT "${sonarcloud_project_properties_content}"
  )

endfunction()
