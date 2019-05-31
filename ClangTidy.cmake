#
# A module to create custom targets to lint source files using clang-tidy
#
# The function swift_setup_clang_tidy will create several targets which will
# use clang-tidy to lint source files. 2 types of targets will be created, one
# for linting all listed source files and the other for linting only those which
# differ from the master branch. The list of file to lint can be created in 2
# ways which are explained below.
#
# The created targets have the names
#
# - clang-tidy-all-${PROJECT_NAME} - lints all files
# - clang-tidy-diff-${PROJECT_NAME} - lints only changed files
#
# In addition if the current project is at the top level of the working tree 2 more
# targets will be created
#
# - clang-tidy-all
# - clang-tidy-diff
#
# which behave in exactly the same way as the namespaced targets.
#
# The parameter SCRIPT can be passed to specify a custom linting script. If given
# the create targets will call this script directly. The script will be passed
# a single argument of 'all' or 'diff' according to the target
#
# clang-tidy-all - will run `<script> all`
# clang-tidy-diff - will run `<script> diff`
#
# If a script is not explicitly passed this function will first search for a 
# custom linting script. The script must exist in ${CMAKE_CURRENT_SOURCE_DIR}/scripts
# and be named either clang-tidy.sh or clang-tidy.bash. It will be called with
# the same arguments as described above.
#
# If no custom script is available this function will generate some default linting
# commands. clang-tidy will be called and passed a list of files to lint. 
#
# The file list can be constructed in one of two ways, either by GLOB patterns or
# a list of targets
#
# GLOB
#   Pass the parameter 'PATTERNS' with 1 or more GLOB patterns as arguments. These
#   patterns will be passed to git directly which will generate a list of files to
#   lint.
#
#   swift_setup_clang_tidy(PATTERNS 'src/*.c' 'src/*.cc' 'src/*.cpp')
#
# TARGETS
#   Pass the parameter 'TARGETS" with 1 or more cmake targets as arguments. These
#   target must already have been created. The list of source files will be extracted
#   from these targets and passed first to git so it can correctly filter them, then
#   to clang-tidy.
#
# This function must be called with one of the above options, or it must be able to
# find a custom script in the file system otherwise it will throw an error.
#
# All commands are run from ${CMAKE_CURRENT_SOURCE_DIR}. It is highly recommended
# that this module only be included from the top level CMakeLists.txt of a project,
# using it from a subdirectory may not work as expected.
#
# In addition this function sets up a cmake option which can be used to control
# whether the targets are created either on the command line or by a super project.
# The option has the name
#
# ${PROJECT_NAME}_ENABLE_CLANG_TIDY
#
# The default value is ON for top level projects, and OFF for any others.
#
# Running 
#
# cmake -D<project>_ENABLE_CLANG_TIDY=OFF ..
#
# will explicitly disable these targets from the command line at configure time
#

# Helper function to actually create the targets, not to be used outside this file
function(create_targets)
  set(argOption "")
  set(argSingle "TOP_LEVEL")
  set(argMulti "ALL_COMMAND" "DIFF_COMMAND")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  add_custom_target(
      clang-tidy-all-${PROJECT_NAME}
      COMMAND ${x_ALL_COMMAND}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )
  add_custom_target(
      clang-tidy-diff-${PROJECT_NAME}
      COMMAND ${x_DIFF_COMMAND}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      )

  # Top level projects will create the targets clang-tidy-all and
  # clang-tidy-diff with the same commands as the namespaced targets
  # above. However, cmake doesn't support aliases for non-library targets
  # so we have to create them fully.
  if(x_TOP_LEVEL)
    add_custom_target(
        clang-tidy-all
        COMMAND ${x_ALL_COMMAND}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
    add_custom_target(
        clang-tidy-diff
        COMMAND ${x_DIFF_COMMAND}
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
  endif()
endfunction()

# Scan a list of targets and build up a list of source files
function(generate_file_list_from_targets)
  set(argOption "")
  set(argSingle "")
  set(argMulti "TARGETS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  foreach(target ${x_TARGETS})
    if(NOT TARGET ${target})
      message(FATAL_ERROR "Trying to enable clang-tidy for target ${target} which doesn't exist")
    endif()

    # Extract the list of source files from the target and convert to absolute paths
    set(target_srcs "")
    set(abs_target_srcs "")
    get_target_property(target_srcs ${target} SOURCES)
    foreach(file ${target_srcs})
      if(${file} MATCHES ".*\\.h$")
        list(REMOVE_ITEM target_srcs ${file})
      endif()
    endforeach()

    list(REMOVE_DUPLICATES target_srcs)

    get_target_property(target_dir ${target} SOURCE_DIR)
    foreach(file ${target_srcs})
      get_filename_component(abs_file ${file} ABSOLUTE BASE_DIR ${target_dir})
      list(APPEND abs_target_srcs ${abs_file})
    endforeach()

    if(abs_target_srcs)
      list(APPEND srcs ${abs_target_srcs})
      set(srcs ${srcs} PARENT_SCOPE)
    else()
      message(WARNING "Target ${target} does not have any lintable sources")
    endif()
  endforeach()
endfunction()

# External function to create clang-tidy-* targets, Call according to the
# documentation in the file header.
function(swift_setup_clang_tidy)
  set(argOption "")
  set(argSingle "SCRIPT")
  set(argMulti "CLANG_TIDY_NAMES" "TARGETS" "PATTERNS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  # Keep track of whether the project cmake option should be on or off by default
  set(default_option_state ON)

  # Global clang-tidy enable option, influences the default project specific enable option
  option(SWIFT_ENABLE_CLANG_TIDY "Enable auto-linting of code using clang-tidy globally" ON)
  if(NOT SWIFT_ENABLE_CLANG_TIDY)
    set(default_option_state OFF)
  endif()

  if(${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    set(top_level_project ON)
  else()
    set(top_level_project OFF)
    # Projects which are not top level have linting disabled by default
    set(default_option_state OFF)
  endif()

  # This is required so that clang-tidy can work out what compiler options to use
  # for each file
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Export compile commands" FORCE)

  # We are going to generate two commands, all and diff, which could be a script or a call
  # directly to clang-tidy. These commands may or may not be found so keep track of whether
  # they are valid. Once they are valid we will be able to create the cmake option and
  # the actual targets
  set(commands_valid FALSE)
  unset(success_msg)
  unset(failure_msg)

  # Use a custom script if explicitly passed
  if(x_SCRIPT)
    if(EXISTS ${x_SCRIPT})
      set(success_msg "Initialising clang tidy targets for ${PROJECT_NAME} using existing script in ${x_SCRIPT}")
      set(all_cmd ${x_SCRIPT} all)
      set(diff_cmd ${x_SCRIPT} diff)
      set(commands_valid TRUE)
    else()
      # The project has specified a script to use, this is not a user configuration option
      # The script doesn't exist so we can bail out early
      message(FATAL_ERROR "Specified clang-tidy script ${x_SCRIPT} doesn't exist")
    endif()
  endif()

  if(NOT commands_valid)
    # Search some default locations for a custom tidy script
    set(custom_scripts "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-tidy.sh" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-tidy.bash")

    foreach(script ${custom_scripts})
      if(EXISTS ${script})
        # Found a valid custom linting script. Set up the commands now but hold off creating
        # the targets for the moment until we know whether or not they are actually enabled
        set(success_msg "Initialising clang tidy target for ${PROJECT_NAME} using existing script in ${script}")
        set(all_cmd ${script} all)
        set(diff_cmd ${script} diff)
        set(commands_valid TRUE)
      endif()
    endforeach()
  endif()

  if(NOT commands_valid)
    # Didn't find a custom script. Generate some default commands

    # First search for an appropriate clang-tidy
    if(NOT x_CLANG_TIDY_NAMES)
      set(x_CLANG_TIDY_NAMES 
          clang-tidy60 clang-tidy-6.0
          clang-tidy40 clang-tidy-4.0
          clang-tidy39 clang-tidy-3.9
          clang-tidy38 clang-tidy-3.8
          clang-tidy37 clang-tidy-3.7
          clang-tidy36 clang-tidy-3.6
          clang-tidy35 clang-tidy-3.5
          clang-tidy34 clang-tidy-3.4
          clang-tidy
        )
    endif()
    find_program(CLANG_TIDY NAMES ${x_CLANG_TIDY_NAMES})

    if("${CLANG_TIDY}" STREQUAL "CLANG_TIDY-NOTFOUND")
      # Can't find a valid clang tidy. We can still continue and just not create
      # the targets so set the default enable option state to off. Also set up
      # a failure message just in case the user is trying to force the targets
      # to be created even though we don't have a linter
      set(failure_msg "Could not find appropriate clang-tidy, can't create targets")
      set(default_option_state FALSE)
    else()
      set(success_msg "Using ${CLANG_TIDY} to auto-lint ${PROJECT_NAME} sources")
      set(${PROJECT_NAME}_CLANG_TIDY ${CLANG_TIDY} CACHE STRING "Absolute path to clang-tidy for ${PROJECT_NAME}")

      # Find a list of source files to tidy
      set(srcs "")
      if(x_TARGETS)
        # Extract a list of source files from each of the specified targets
        generate_file_list_from_targets(TARGETS ${x_TARGETS})
      elseif(x_PATTERNS)
        # Just use the provided pattern as the file list
        set(srcs ${x_PATTERNS})
      else()
        message(FATAL_ERROR "ClangTidy modules must be set up to use either a custom script, a list of targets, or file patterns")
      endif()

      if(NOT srcs)
        # Not finding any source files could be a fatal error, or it could be ignored if the user
        # is not trying to force the targets to be created. Set up the default option value, generate
        # a failure message and leave the processing until later
        set(failure_msg "Couldn't find any source/header files to tidy in ${PROJECT_NAME}")
        set(default_option_state OFF)
      else()
        # Now we have a list of source files we can generate the commands to be used for the
        # targets. Everything should be set up properly after this
        set(all_command
            ${${PROJECT_NAME}_CLANG_TIDY} -p ${CMAKE_BINARY_DIR} --export-fixes=${CMAKE_CURRENT_SOURCE_DIR}/fixes.yaml
            `git ls-files ${srcs}`
          )
        set(diff_command
            ${${PROJECT_NAME}_CLANG_TIDY} -p ${CMAKE_BINARY_DIR} --export-fixes=${CMAKE_CURRENT_SOURCE_DIR}/fixes.yaml
            `git diff --diff-filter=ACMRTUXB --name-only master -- ${srcs}`
          )
        set(commands_valid TRUE)
      endif()
    endif()
  endif()

  # Create a cmake option to enable linting of this specific project
  option(${PROJECT_NAME}_ENABLE_CLANG_TIDY "Enable auto-linting of code using clang-tidy for project ${PROJECT_NAME}" ${default_option_state})

  if(${PROJECT_NAME}_ENABLE_CLANG_TIDY)
    # Linting has been enabled, either by the default option or because a user
    # has explicitly enabled it on the command line
    if(commands_valid)
      # We have some valid commands to start the linting process so we
      # can create the targets
      message(STATUS "${success_msg}")
      create_targets(
          TOP_LEVEL ${top_level_project}
          ALL_COMMAND ${all_command}
          DIFF_COMMAND ${diff_command}
          )
    else()
      # Without valid commands linting is impossible. If we get here then the user
      # has explicitly tried to enable auto-linting on the command line, since that
      # is impossible we will thrown a fatal error here using a message previously
      # generated
      message(FATAL_ERROR "${failure_msg}")
    endif()
  else()
    # Linting is either not possible or not requested for this project, skip
    # target creation
    if(failure_msg)
      # We may have encountered an error, but since the target would have been
      # disabled anyway it's not a big deal. Just log it so the user is aware
      message(STATUS "${failure_msg}")
    endif()
    message(STATUS "clang-tidy for project ${PROJECT_NAME} is DISABLED")
  endif()
endfunction()
