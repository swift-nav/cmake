#
### OVERVIEW
#
# This module introduces various functions, each corresponds to a Valgrind tool.
#
# AVAILABLE TOOLS:
#   memcheck  - memory error detector
#   massif    - measures how much heap memory your program uses
#   callgrind - records the call history among functions in a program's run as a
#               call-graph
#
### USAGE
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
# results to `${CMAKE_CURRENT_BINARY_DIR}/valgrind-reports/callgrind-unit-tests`.
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
#   * WORKSPACE
#   * TRACE_CHILDREN
#   * SILENT_CHILD_AFTER_FORK
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
# WORKING_DIRECTORY enables a user to change the output directory for the tools
# from the default folder `${CMAKE_CURRENT_BINARY_DIR}`. Setting this option for
# target `valgrind-callgrind-suite-2` to `/tmp`, outputs the results
# `/tmp/valgrind-reports/suite-2`.
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
# LEAK_CHECK searches for memory leaks when the application finishes.
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
# STACKS specifies whether stack profiling should be done. This option slows
# Massif down greatly.
#
# PAGES_AS_HEAP tells Massif to profile memory at the page level rather than at
# the malloc'd  block level.
#
# TIME_UNIT offers three settings:
#
#   * Instructions executed `i`, which is good for most cases.
#   * Time `ms`, which is sometimes useful.
#   * Bytes allocated/deallocated on the heap and/or stack `B`, which is useful
#     for very short-run programs and for testing purposes.
#
### NOTES
#
# The callgrind `*.out.*` files are not human readable, as such one might want
# to load the files with the `KCacheGrind` program to easily navigate the data.
#

find_package(Valgrind)

if (NOT Valgrind_FOUND)
  message(WARNING "Unable to create Valgrind targets due to missing program")
endif ()

macro(_valgrind_basic_setup _target)
  if (NOT TARGET ${_target})
    message(FATAL_ERROR "Specified target \"${_target}\" does not exist")
  endif()

  get_target_property(_target_type ${_target} TYPE)

  if (NOT _target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${_target}\" must be an executable type")
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

macro(_valgrind_arguments_setup _target _tool_name _toolOptions _toolSingle _toolMulti _ARGN)
  set(_commonOptions CHILD_SILENT_AFTER_FORK TRACE_CHILDREN)
  set(_commonSingle NAME WORKING_DIRECTORY)
  set(_commonMulti PROGRAM_ARGS)

  set(_argOption ${_commonOptions} ${_toolOptions})
  set(_argSingle ${_commonSingle} ${_toolSingle})
  set(_argMulti ${_commonMulti} ${_toolMulti})

  cmake_parse_arguments(x "${_argOption}" "${_argSingle}" "${_argMulti}" ${_ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(target_name valgrind-${_tool_name}-${_target})
  set(report_folder ${_tool_name}-${target})
  if (x_NAME)
    set(target_name valgrind-${_tool_name}-${x_NAME})
    set(report_folder ${_tool_name}-${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  unset(valgrind_tool_options)
  if (x_CHILD_SILENT_AFTER_FORK)
    list(APPEND valgrind_tool_options --child-silent-after-fork=yes)
  endif()

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --trace-children=yes)
    list(APPEND valgrind_tool_options --log-file=${target}.log.%p)
  else()
    list(APPEND valgrind_tool_options --log-file=${target}.log)
  endif()

  set(reports_directory ${working_directory}/valgrind-reports)
endmacro()

function(swift_add_valgrind_memcheck target)
  set(argOption SHOW_REACHABLE TRACK_ORIGINS UNDEF_VALUE_ERRORS)
  set(argSingle LEAK_CHECK)
  set(argMulti "")

  _valgrind_arguments_setup(${target} memcheck "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")
  _valgrind_basic_setup(${target})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --xml=yes --xml-file=${target}.xml.%p)
  else()
    list(APPEND valgrind_tool_options --xml=yes --xml-file=${target}.xml)
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

  add_custom_target(${target_name}
    COMMENT "Valgrind Memcheck is running for \"${target}\" (output: \"${reports_directory}/${report_folder}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory}/${report_folder} ${Valgrind_EXECUTABLE} --tool=memcheck ${valgrind_tool_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-memcheck)
    add_custom_target(do-all-valgrind-memcheck)
  endif()
  add_dependencies(do-all-valgrind-memcheck ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-memcheck)
endfunction()

function(swift_add_valgrind_callgrind target)
  set(argOption "")
  set(argSingle "")
  set(argMulti "")

  _valgrind_arguments_setup(${target} callgrind "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")
  _valgrind_basic_setup(${target})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --callgrind-out-file=${target}.out.%p)
  else()
    list(APPEND valgrind_tool_options --callgrind-out-file=${target}.out)
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Callgrind is running for \"${target}\" (output: \"${reports_directory}/${report_folder}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory}/${report_folder} ${Valgrind_EXECUTABLE} --tool=callgrind ${valgrind_tool_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-callgrind)
    add_custom_target(do-all-valgrind-callgrind)
  endif()
  add_dependencies(do-all-valgrind-callgrind ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-callgrind)
endfunction()

function(swift_add_valgrind_massif target)
  set(argOption STACKS PAGES_AS_HEAP XTREE_MEMORY)
  set(argSingle TIME_UNIT)
  set(argMulti "")

  _valgrind_arguments_setup(${target} massif "${argOption}" "${argSingle}" "${argMulti}" "${ARGN}")
  _valgrind_basic_setup(${target})

  if (x_TRACE_CHILDREN)
    list(APPEND valgrind_tool_options --massif-out-file=${target}.out.%p)
  else()
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
    list(APPEND valgrind_tool_options "--time-unit=${x_TIME_UNIT}")
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Massif is running for \"${target}\" (output: \"${reports_directory}/${report_folder}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory}/${report_folder} ${Valgrind_EXECUTABLE} --tool=massif ${valgrind_tool_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-massif)
    add_custom_target(do-all-valgrind-massif)
  endif()
  add_dependencies(do-all-valgrind-massif ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-massif)
 endfunction()
