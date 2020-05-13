#
### OVERVIEW
#
# This module introduces various functions where each correspond to a Valgrind tool.
# These functions create cmake targets that run their specified target executable applying
# the selected tool.
#
# AVAILABLE TOOLS:
# callgrind - records the call history among functions in a program's run as a call-graph
# memcheck  - memory error detector
# massif    - measures how much heap memory your program uses
#
### USAGE
#
#   swift_add_valgrind_callgrind(<target>
#     [callgrind options]
#     [NAME target_name]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which runs the executable
# created by the specified `target` argument through Valgrind's Callgrind tool.
# Example: a cmake target is called `unit-tests` and is invoked by the callgrind
# function `swift_add_valgrind_callgrind(unit-tests)`, resulting in the following
# cmake targets:
#
#   - unit-tests-valgrind-callgrind
#   - do-all-valgrind-callgrind
#   - do-all-valgrind
#
# The first target runs the `unit-tests` target, and generates the
# callgrind's results to folder `${CMAKE_CURRENT_BINARY_DIR}/valgrind-callgrind-reports`.
# The results consist of `unit-tests.log*` files and
# `unit-tests.out.*`. The number suffix corresponds to the process ID
# of the running program. A result with multiple PIDs is due to the original
# target spawned off child processes and the option `TRACE_CHILDREN` has been selected,
# otherwise it wouldn't report on the spawned children. Rerunning this target
# erases any prior results.
#
# The next two targets are handy targets that exists to help call on the various
# registered valgrind tests.
# The `do-all-valgrind-callgrind` invokes all targets that have called on the
# `swift_add_valgrind_callgrind` function.
# The `do-all-valgrind` invokes all targets that have called on any of the functions
# mentioned within this documentation.
#
### VALGRIND OPTIONS available for all functions:
#
# NAME specifies the name of the new target created. This is quite useful if you'd like to
# create multiple valgrind-tool targets from a single cmake target executable.
# Example: Continuing on with the `unit-tests` example above, if the target is a
# Googletest executable, and it's desirable to break the test cases across different suites,
# it's possible to create two targets (not including `do-all-code-profiling` in this
# number) `suite-1-profiles` and `suite-2-profiles`, each calling the
# `unit-tests` executable with different program arguments:
#
#   swift_add_code_profiling(unit-tests
#     NAME suite-1-profiles
#     PROGRAM_ARGS --gtest_filter=Suite1.*
#   )
#
#   swift_add_code_profiling(unit-tests
#     NAME suite-2-profiles
#     PROGRAM_ARGS --gtest_filter=Suite2.*
#   )
#
# WORKING_DIRECTORY enables a user to change the output directory from the default folder
# `${CMAKE_CURRENT_BINARY_DIR}`.
# Example: Setting this option for target `suite-2-profiles` to `/tmp`, outputs the profiling
# results to `/tmp/valgrind-callgrind-reports/suite-2-profiles*`.
# 
# TRACE_CHILDREN invokes the Valgrind tools even on spawned children,
# normally ignores the spawned processes.
#
# CHILD_SILENT_AFTER_FORK instructs Valgrind to hide any debugging or logging output for
# a child process resulting from a fork call. This can make the output less confusing
# (although more misleading) when dealing with processes that create children.
#
### MALLOC()-RELATED OPTIONS:
# For tools that use their own version of malloc (e.g. Memcheck, Massif, Helgrind, DRD).
#
# XTREE_MEMORY produces an execution tree detailing which piece of code is responsible for
# heap memory usage. Argument `full` gives 6 different measurements, the current number of
# allocated bytes and blocks (same values as for allocs), the total number of allocated bytes
# and blocks, the total number of freed bytes and blocks.
#
### MEMCHECK SPECIFIC OPTIONS:
#
# LEAK_CHECK searches for memory leaks when the application finishes.
# If set to summary, it says how many leaks occurred.
# If set to full or yes, each individual leak will be shown in detail and/or counted as an
# error, as specified by the options --show-leak-kinds.
#
# SHOW_REACHABLE is equivalent to --show-leak-kinds=all whichs specifies the complete set
# (showing all leak kinds).
#
# TRACK_ORIGINS controls whether Memcheck tracks the origin of uninitialised values.
#
# UNDEF_VALUE_ERRORS controls whether Memcheck reports uses of undefined value errors.
#
### MASSIF SPECIFIC OPTIONS:
#
# STACKS specifies whether stack profiling should be done. This option slows Massif down
# greatly.
#
# PAGES_AS_HEAP tells Massif to profile memory at the page level rather than at the malloc'd
# block level.
#
# TIME_UNIT offers three settings:
# Instructions executed `i`, which is good for most cases.
# Time `ms`, which is sometimes useful.
# Bytes allocated/deallocated on the heap and/or stack `B`, which is useful for very
# short-run programs and for testing purposes.
#
### NOTES
#
# The callgrind `unit-tests.out.*` files are not human readable, as such one might want to
# load the files with the `KCacheGrind` program to easily navigate the data.
#

find_package(Valgrind)

if (NOT Valgrind_FOUND)
  message(WARNING "Unable to create Valgrind checks due to missing program")
endif ()

macro(_valgrind_executable_setup target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(_target_type ${target} TYPE)

  if (NOT _target_type STREQUAL "EXECUTABLE")
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type")
  endif()

  if (NOT Valgrind_FOUND)
    return()
  endif ()

  if (CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  if (NOT TARGET do-all-valgrind)
    add_custom_target(do-all-valgrind)
  endif()
endmacro()

macro(_valgrind_tools_setup target tool)
  set(argOption "")
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name ${target}-${tool})
  if (x_NAME)
    set(target_name ${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()
  set(valgrind-reports-dir ${working_directory}/${tool}-reports)
endmacro()

function(swift_add_valgrind_memcheck target)
  set(argOption TRACE_CHILDREN CHILD_SILENT_AFTER_FORK SHOW_REACHABLE TRACK_ORIGINS UNDEF_VALUE_ERRORS)
  set(argSingle LEAK_CHECK)
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  _valgrind_executable_setup(${target})
  _valgrind_tools_setup(${target} valgrind-memcheck ${x_UNPARSED_ARGUMENTS})

  unset(valgrind_tool_options)
  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --trace-children=yes)
  endif()

  if (x_CHILD_SILENT_AFTER_FORK)
    list(APPEND valgrind_tool_options --child-silent-after-fork=yes)
  endif()

  if (x_SHOW_REACHABLE)
    list(APPEND valgrind_tool_options --show-reachable=yes)
  endif()

  if (x_TRACK_ORIGINS)
    list(APPEND valgrind_tool_options --track-origins=yes)
  endif()

  if (x_UNDEF_VALUE_ERRORS)
    list(APPEND valgrind_tool_options --undef-value-errors=yes)
  endif()

  if (x_LEAK_CHECK)
    if (${x_LEAK_CHECK} STREQUAL "yes")
      list(APPEND valgrind_tool_options --leak-check=yes)
    elseif (${x_LEAK_CHECK} STREQUAL "full")
      list(APPEND valgrind_tool_options --leak-check=full)
    elseif (${x_LEAK_CHECK} STREQUAL "summary")
      list(APPEND valgrind_tool_options --leak-check=summary)
    endif()
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Memcheck is running for \"${target}\" (output: \"${valgrind-reports-dir}/\")"
    COMMAND ${CMAKE_COMMAND} -E remove ${valgrind-reports-dir}/${target}*
    COMMAND ${CMAKE_COMMAND} -E make_directory ${valgrind-reports-dir}
    COMMAND ${CMAKE_COMMAND} -E chdir ${valgrind-reports-dir} ${Valgrind_EXECUTABLE} --tool=memcheck ${valgrind_tool_options} --xml=yes --xml-file=${target}.xml $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-memcheck)
    add_custom_target(do-all-valgrind-memcheck)
  endif()
  add_dependencies(do-all-valgrind-memcheck ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-memcheck)
endfunction()

function(swift_add_valgrind_callgrind target)
  set(argOption TRACE_CHILDREN)
  set(argSingle "")
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  _valgrind_executable_setup(${target})
  _valgrind_tools_setup(${target} valgrind-callgrind ${x_UNPARSED_ARGUMENTS})

  unset(valgrind_tool_options)
  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --trace-children=yes)
    list(APPEND valgrind_tool_options --log-file=${target}.log.%p)
    list(APPEND valgrind_tool_options --callgrind-out-file=${target}.out.%p)
  else()
    list(APPEND valgrind_tool_options --log-file=${target}.log)
    list(APPEND valgrind_tool_options --callgrind-out-file=${target}.out)
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Callgrind is running for \"${target}\" (output: \"${valgrind-reports-dir}/\")"
    COMMAND ${CMAKE_COMMAND} -E remove ${valgrind-reports-dir}/${target}*
    COMMAND ${CMAKE_COMMAND} -E make_directory ${valgrind-reports-dir}
    COMMAND ${CMAKE_COMMAND} -E chdir ${valgrind-reports-dir} ${Valgrind_EXECUTABLE} --tool=callgrind ${valgrind_tool_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-callgrind)
    add_custom_target(do-all-valgrind-callgrind)
  endif()
  add_dependencies(do-all-valgrind-callgrind ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-callgrind)
endfunction()

function(swift_add_valgrind_massif target)
  set(argOption TRACE_CHILDREN STACKS PAGES_AS_HEAP XTREE_MEMORY)
  set(argSingle TIME_UNIT)
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  _valgrind_executable_setup(${target})
  _valgrind_tools_setup(${target} valgrind-massif ${x_UNPARSED_ARGUMENTS})

  unset(valgrind_tool_options)
  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --trace-children=yes)
    list(APPEND valgrind_tool_options --log-file=${target}.log.%p)
    list(APPEND valgrind_tool_options --massif-out-file=${target}.out.%p)
  else()
    list(APPEND valgrind_tool_options --log-file=${target}.log)
    list(APPEND valgrind_tool_options --massif-out-file=${target}.out)
  endif()

  if (x_STACKS)
    list(APPEND valgrind_tool_options --stacks=yes)
  endif()

  if (x_PAGES_AS_HEAP)
    list(APPEND valgrind_tool_options --pages-as-heap=yes)
  endif()

  if (x_XTREE_MEMORY)
    list(APPEND valgrind_tool_options --xtree-memory=full)
    list(APPEND valgrind_tool_options --xtree-memory-file=${target}.kcg.%p)
  endif()

  if (x_TIME_UNIT)
    if (${x_TIME_UNIT} STREQUAL "i")
      list(APPEND valgrind_tool_options --time-unit=i)
    elseif (${x_TIME_UNIT} STREQUAL "ms")
      list(APPEND valgrind_tool_options --time-unit=ms)
    elseif (${x_TIME_UNIT} STREQUAL "B")
      list(APPEND valgrind_tool_options --time-unit=B)
    endif()
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Massif is running for \"${target}\" (output: \"${valgrind-reports-dir}/\")"
    COMMAND ${CMAKE_COMMAND} -E remove ${valgrind-reports-dir}/${target}*
    COMMAND ${CMAKE_COMMAND} -E make_directory ${valgrind-reports-dir}
    COMMAND ${CMAKE_COMMAND} -E chdir ${valgrind-reports-dir} ${Valgrind_EXECUTABLE} --tool=massif ${valgrind_tool_options} $<TARGET_FILE:${target}>
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-massif)
    add_custom_target(do-all-valgrind-massif)
  endif()
  add_dependencies(do-all-valgrind-massif ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-massif)
 endfunction()
