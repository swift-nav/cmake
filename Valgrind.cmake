#
# OVERVIEW
#
# This module introduces various Valgrind tools, which are used for profiling
# purposes.
#
# AVAILABLE TOOLS:
#   memcheck  - memory error detector
#   massif    - measures how much heap memory your program uses
#   callgrind - records the call history among functions in a program's run as a
#               call-graph
#
# USAGE
#
#   swift_add_valgrind_*(<target>
#     [... list of common options ...]
#     [... list of tool specific options ...]
#   )
#
# In this signature, the asterisk is a wildcard for any of the above available
# tools, so to call on the `callgrind` tool, use `swift_add_valgrind_callgrind`.
#
# These functions create new cmake targets which runs the `target`'s executable
# binary through Valgrind's tool. Invoking the `swift_add_valgrind_callgrind(unit-tests)`,
# results in the following new cmake targets:
#
#   - valgrind-callgrind-unit-tests
#   - do-all-valgrind-callgrind
#   - do-all-valgrind
#
# The first target runs the `unit-tests` target, and generates the callgrind's
# results to the default folder
#`${CMAKE_BINARY_DIR}/profiling/valgrind-reports/callgrind-unit-tests`.
#
# The next two targets are handy targets that exists to help call on the various
# registered valgrind tests. The `do-all-valgrind-callgrind` invokes all targets
# that have called on the `swift_add_valgrind_callgrind` function. The
# `do-all-valgrind` invokes all targets that have called on any of the
# `swift_add_valgrind_*` function.
#
### COMMON OPTIONS
#
# There are a number of options that are shared across all the
# `swift_add_valgrind_*` functions:
#
#   * NAME
#   * WORKING_DIRECTORY
#   * REPORT_DIRECTORY
#   * PROGRAM_ARGS
#   * TRACE_CHILDREN
#   * CHILD_SILENT_AFTER_FORK
#
# NAME specifies the name to use for the new target created. This is quite
# useful if you'd like to create multiple valgrind-tool targets from a single
# cmake target executable. Continuing on with the `unit-tests` example above, if
# the target is a Googletest executable, and it's desirable to break the test
# cases across different suites, it's possible to create two targets (not
# including `do-all-valgrind` and `do-all-callgrind` in this this) using the
# following code:
#
#   swift_add_code_profiling(unit-tests
#     NAME suite-1
#     PROGRAM_ARGS --gtest_filter=Suite1.*
#   )
#
#   swift_add_code_profiling(unit-tests
#     NAME suite-2
#     PROGRAM_ARGS --gtest_filter=Suite2.*
#   )
#
# This creates `valgrind-callgrind-suite-1` and `valgrind-callgrind-suite-2`,
# each calling the `unit-tests` executable with different program arguments.
#
# WORKING_DIRECTORY enables a user to change the execution directory for the tool
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}` to the given argument.
# For instance, if a user wants to utilize files located in a specific folder.
#
# REPORT_DIRECTORY enables a user to change the output directory for the tool
# from the default folder `${CMAKE_BINARY_DIR}/profiling/valgrind-reports`.
# Example, using argument `/tmp`, outputs the results to `/tmp`.
#
# PROGRAM_ARGS specifies target arguments. Example, using a yaml configuration
# with "--config example.yaml".
#
# TRACE_CHILDREN invokes the Valgrind tools even on spawned children, normally
# ignores the spawned processes.
#
# CHILD_SILENT_AFTER_FORK instructs Valgrind to hide any debugging or logging
# output for a child process resulting from a fork call. This can make the
# output less confusing (although more misleading) when dealing with processes
# that create children.
#
### MALLOC()-RELATED OPTIONS:
#
# For tools that use their own version of malloc (e.g. Memcheck, Massif,
# Helgrind, DRD).
#
# XTREE_MEMORY produces an execution tree detailing which piece of code is
# responsible for heap memory usage. Argument `full` gives 6 different
# measurements, the current number of allocated bytes and blocks (same values as
# for allocs), the total number of allocated bytes and blocks, the total number
# of freed bytes and blocks.
#
### MEMCHECK SPECIFIC OPTIONS:
#
# LEAK_CHECK=<no|summary|yes|full> [default: summary], searches for memory leaks
# when the application finishes.
#
#   * If set to `summary`, it says how many leaks occurred.
#   * If set to `full` or `yes`, each individual leak will be shown in detail
#     and/or counted as an error, as specified by the options --show-leak-kinds.
#
# SHOW_REACHABLE is equivalent to `--show-leak-kinds=all` which specifies the
# complete set (showing all leak kinds).
#
# TRACK_ORIGINS controls whether Memcheck tracks the origin of uninitialised
# values.
#
# UNDEF_VALUE_ERRORS controls whether Memcheck reports uses of undefined value
# errors.
#
### MASSIF SPECIFIC OPTIONS:
#
# DEPTH=<number> [default: 30], maximum depth of the allocation trees recorded
# for detailed snapshots.
#
# DETAILED_FREQUENCY=<number> [default: 10], frequency of detailed snapshots.
# With value of `1`, every snapshot is detailed.
#
# MAX_SNAPSHOTS=<number> [default: 100], the maximum number of snapshots
# recorded.
#
# PEAK_INACCURACY=<float> [default: 1.0], Massif does not necessarily record
# the actual global memory allocation peak; by default it records a peak only
# when the global memory allocation size exceeds the previous peak by at least
# 1.0%. Setting this value to `0.0` gives the true value of the peak.
#
# STACKS specifies whether stack profiling should be done. This option slows
# Massif down greatly.
#
# PAGES_AS_HEAP tells Massif to profile memory at the page level rather than at
# the malloc'd  block level.
#
# TIME_UNIT=<i|ms|B>, offers three settings:
#
#   * Instructions executed `i`, which is good for most cases.
#   * Time `ms`, which is sometimes useful.
#   * Bytes allocated/deallocated on the heap and/or stack `B`, which is useful
#     for very short-run programs and for testing purposes.
#
# THRESHOLD=<float> [default: 1.0], the significance threshold for heap
# allocations, as a percentage of total memory size. Allocation tree entries
# that account for less than this will be aggregated.
#
### NOTES
#
# * The callgrind `*.out.*` files are not human readable, as such one might want
# to load the files with the `KCacheGrind` program to easily navigate the data.
#
# * A cmake option is available to control whether targets should be built,
# with the name ${PROJECT_NAME}_ENABLE_PROFILING.
#
# Running
#
# cmake -D<project>_ENABLE_PROFILING=ON ..
#
# will explicitly enable these targets from the command line at configure time.
#

option(${PROJECT_NAME}_ENABLE_PROFILING "Builds targets with profiling applied" OFF)

find_package(Valgrind)

if (NOT Valgrind_FOUND AND ${PROJECT_NAME}_ENABLE_PROFILING)
  message(WARNING "Unable to create Valgrind targets due to missing program")
endif()

macro(_valgrind_basic_setup _target)
  if (NOT TARGET ${_target})
    message(FATAL_ERROR "Specified target \"${_target}\" does not exist")
  endif()

  get_target_property(_target_type ${_target} TYPE)
  if (NOT _target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${_target}\" must be an executable type to register for profiling with Valgrind")
  endif()

  if (NOT (${CMAKE_BUILD_TYPE} STREQUAL "Debug" OR
           ${CMAKE_BUILD_TYPE} STREQUAL "RelWithDebInfo"))
    message(WARNING "Use Debug or RelWithDebInfo as cmake build type to get debug info from Valgrind")
  endif()

  if (NOT (Valgrind_FOUND AND
           ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME} AND
           ${PROJECT_NAME}_ENABLE_PROFILING)
      OR CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT TARGET do-all-valgrind)
    add_custom_target(do-all-valgrind)
  endif()
endmacro()

macro(_valgrind_arguments_setup _target _tool_name _toolOptions _toolSingle _toolMulti _ARGN)
  set(_commonOptions CHILD_SILENT_AFTER_FORK TRACE_CHILDREN)
  set(_commonSingle NAME WORKING_DIRECTORY REPORT_DIRECTORY)
  set(_commonMulti PROGRAM_ARGS)

  set(_argOption ${_commonOptions} ${_toolOptions})
  set(_argSingle ${_commonSingle} ${_toolSingle})
  set(_argMulti ${_commonMulti} ${_toolMulti})

  cmake_parse_arguments(x "${_argOption}" "${_argSingle}" "${_argMulti}" ${_ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name valgrind-${_tool_name}-${_target})
  set(report_folder ${_tool_name}-${_target})
  if (x_NAME)
    set(target_name valgrind-${_tool_name}-${x_NAME})
    set(report_folder ${_tool_name}-${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  set(report_directory ${CMAKE_BINARY_DIR}/profiling/valgrind-reports)
  if (x_REPORT_DIRECTORY)
    set(report_directory ${x_REPORT_DIRECTORY})
  endif()

  set(output_file ${report_directory}/${report_folder}/${target_name})

  unset(valgrind_tool_options)
  if (x_CHILD_SILENT_AFTER_FORK)
    list(APPEND valgrind_tool_options --child-silent-after-fork=yes)
  endif()

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --trace-children=yes)
    list(APPEND valgrind_tool_options --log-file=${output_file}.log.%p)
  else()
    list(APPEND valgrind_tool_options --log-file=${output_file}.log)
  endif()
endmacro()

macro(setup_custom_target valgrind_tool target_name)
  add_custom_target(${target_name}
    COMMENT "Valgrind ${valgrind_tool} is running for \"${target}\" (output: \"${report_directory}/${report_folder}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${report_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${report_directory}/${report_folder}
    COMMAND ${Valgrind_EXECUTABLE} ${valgrind_tool_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    WORKING_DIRECTORY ${working_directory}
    DEPENDS ${target}
  )
  if (NOT TARGET do-all-valgrind-${valgrind_tool})
    add_custom_target(do-all-valgrind-${valgrind_tool})
  endif()
  add_dependencies(do-all-valgrind-${valgrind_tool} ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-${valgrind_tool})
endmacro()

function(swift_add_valgrind_memcheck target)
  set(argOption SHOW_REACHABLE TRACK_ORIGINS UNDEF_VALUE_ERRORS)
  set(argSingle LEAK_CHECK)
  set(argMulti "")

  set(valgrind_tool memcheck)
  _valgrind_basic_setup(${target})
  _valgrind_arguments_setup(${target} ${valgrind_tool} "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  list(APPEND valgrind_tool_options --tool=${valgrind_tool})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --xml=yes --xml-file=${output_file}.xml.%p)
  else()
    list(APPEND valgrind_tool_options --xml=yes --xml-file=${output_file}.xml)
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
    list(APPEND valgrind_tool_options "--leak-check=${x_LEAK_CHECK}")
  endif()

  setup_custom_target(${valgrind_tool} ${target_name})
endfunction()

function(swift_add_valgrind_callgrind target)
  set(argOption "")
  set(argSingle "")
  set(argMulti "")

  set(valgrind_tool callgrind)
  _valgrind_basic_setup(${target})
  _valgrind_arguments_setup(${target} ${valgrind_tool} "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  list(APPEND valgrind_tool_options --tool=${valgrind_tool})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --callgrind-out-file=${output_file}.out.%p)
  else()
    list(APPEND valgrind_tool_options --callgrind-out-file=${output_file}.out)
  endif()

  setup_custom_target(${valgrind_tool} ${target_name})
endfunction()

function(swift_add_valgrind_massif target)
  set(argOption STACKS PAGES_AS_HEAP XTREE_MEMORY)
  set(argSingle DEPTH DETAILED_FREQUENCY MAX_SNAPSHOTS PEAK_INACCURACY THRESHOLD TIME_UNIT)
  set(argMulti "")

  set(valgrind_tool massif)
  _valgrind_basic_setup(${target})
  _valgrind_arguments_setup(${target} ${valgrind_tool} "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")

  list(APPEND valgrind_tool_options --tool=${valgrind_tool})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --massif-out-file=${output_file}.out.%p)
  else()
    list(APPEND valgrind_tool_options --massif-out-file=${output_file}.out)
  endif()

  if (x_STACKS)
    list(APPEND valgrind_tool_options --stacks=yes)
  endif()

  if (x_PAGES_AS_HEAP)
    list(APPEND valgrind_tool_options --pages-as-heap=yes)
  endif()

  if (x_XTREE_MEMORY)
    list(APPEND valgrind_tool_options --xtree-memory=full)
    list(APPEND valgrind_tool_options --xtree-memory-file=${output_file}.kcg.%p)
  endif()

  if (x_DEPTH)
    list(APPEND valgrind_tool_options "--depth=${x_DEPTH}")
  endif()

  if (x_DETAILED_FREQUENCY)
    list(APPEND valgrind_tool_options "--detailed-freq=${x_DETAILED_FREQUENCY}")
  endif()

  if (x_MAX_SNAPSHOTS)
    list(APPEND valgrind_tool_options "--max-snapshots=${x_MAX_SNAPSHOTS}")
  endif()

  if (x_PEAK_INACCURACY)
    list(APPEND valgrind_tool_options "--peak-inaccuracy=${x_PEAK_INACCURACY}")
  endif()

  if (x_THRESHOLD)
    list(APPEND valgrind_tool_options "--threshold=${x_THRESHOLD}")
  endif()

  if (x_TIME_UNIT)
    list(APPEND valgrind_tool_options "--time-unit=${x_TIME_UNIT}")
  endif()

  setup_custom_target(${valgrind_tool} ${target_name})
 endfunction()
