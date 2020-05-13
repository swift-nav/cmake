#
# OVERVIEW
#
# This module will introduce various function which will create cmake targets
# that run their specified target executable targets through various Valgrind
# tools.
#
# USAGE
#
#   swift_add_valgrind_callgrind(<target>
#     [TRACE_CHILDREN]
#     [NAME target_name]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which will run the executable
# created by the specified `target` argument through Valgrind's Callgrind tool.
# For instance if there was a cmake target called `unit-tests` and I invoked the
# function as `swift_add_valgrind_callgrind(unit-tests)`, it would produce the
# following cmake targets:
#
#   - unit-tests-valgrind-callgrind
#   - do-all-valgrind-callgrind
#   - do-all-valgrind
#
# The first target will run the `unit-tests` target, and generates the
# callgrind's results to the `${CMAKE_CURRENT_BINARY_DIR}/unit-tests-valgrind-callgrind`
# folder. The results will consisted of `callgrind.log*` files and
# `callgrind.out.*`. The numbers that you see corresponds to the process ID of
# the running program, if you see multiple PIDs, that's because the original
# target spawned off child processes and you've se the `TRACE_CHILDREN` option,
# otherwise it wouldn't report on the spawned children. Rerunning this target
# will mean that any prior results will be cleared out.
#
# The next two targets are handy targets that exists to help call on the various
# registered valgrind tests. The `do-all-valgrind-callgrind` will invoke all
# targets that have called on the `swift_add_valgrind_callgrind` function,
# `do-all-valgrind` invokes all targets that have called on any of the functions
# mentioned within this documentation.
#
# There are a few options that are available to the funciton. TRACE_CHILDREN as
# you might have seens before, invokes the callgrind tool even on spawned
# children, normally ignores the spawned processes.
#
# The NAME option is there to specify the name of the new target created, this
# is quite useful if you'd like to create multiple callgrind targets from a
# single cmake target executable. Continuing on with our `unit-tests` example,
# if the target was a Googletest executable, and we wanted to break the tests
# cases across different suites, we could do something like the following:
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
# This would create two targets (not including `do-all-code-profiling` in this
# number) `suite-1-profiles` and `suite-2-profiles`, each calling the
# `unit-tests` executable with different program arguments.
#
# The last option WORKING_DIRECTORY is simply there to redirect the output
# results to a different folder. By default that folder is
# `${CMAKE_CURRENT_BINARY_DIR}`, if we set that option for `suite-2-profiles` to
# `/tmp`, it would output the profiling results to `/tmp/suite-2-profiles`.
#
# NOTES
#
# The `callgrind.out.*` files are not human readable, as such one might want to
# load the files with the `KCacheGrind` program to easily navigate the data.
#

find_package(Valgrind)

if (NOT Valgrind_FOUND)
  message(WARNING "Unable to create Valgrind checks due to missing program")
endif ()

macro(_valgrind_setup target)
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

function(swift_add_valgrind_memcheck target)
  set(argOption "TRACE_CHILDREN" "CHILD_SILENT_AFTER_FORK" "SHOW_REACHABLE" "TRACK_ORIGINS" "UNDEF_VALUE_ERRORS")
  set(argSingle "LEAK_CHECK")
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  _valgrind_setup(${target})
  unset(MEMCHECK_OPTIONS)

  if (x_TRACE_CHILDREN)
    list(APPEND MEMCHECK_OPTIONS "--trace-children=yes")
  endif()

  if (x_CHILD_SILENT_AFTER_FORK)
    list(APPEND MEMCHECK_OPTIONS "--child-silent-after-fork=yes")
  endif()

  if (x_SHOW_REACHABLE)
    list(APPEND MEMCHECK_OPTIONS "--show-reachable=yes")
  endif()

  if (x_TRACK_ORIGINS)
    list(APPEND MEMCHECK_OPTIONS "--track-origins=yes")
  endif()

  if (x_UNDEF_VALUE_ERRORS)
    list(APPEND MEMCHECK_OPTIONS "--undef-value-errors=yes")
  endif()

  if (x_LEAK_CHECK)
    if (${x_LEAK_CHECK} STREQUAL "yes")
      list(APPEND MEMCHECK_OPTIONS "--leak-check=yes")
    elseif (${x_LEAK_CHECK} STREQUAL "no")
      list(APPEND MEMCHECK_OPTIONS "--leak-check=no")
    elseif (${x_LEAK_CHECK} STREQUAL "full")
      list(APPEND MEMCHECK_OPTIONS "--leak-check=full")
    elseif (${x_LEAK_CHECK} STREQUAL "summary")
      list(APPEND MEMCHECK_OPTIONS "--leak-check=summary")
    endif()
  endif()

  set(valgrind-reports-dir ${CMAKE_CURRENT_BINARY_DIR}/valgrind-reports)
  add_custom_target(${target}-memcheck
    COMMAND ${CMAKE_COMMAND} -E make_directory ${valgrind-reports-dir}
    COMMAND ${CMAKE_COMMAND} -E chdir ${valgrind-reports-dir} ${Valgrind_EXECUTABLE} --tool=memcheck ${MEMCHECK_OPTIONS} --xml=yes --xml-file=${target}.xml $<TARGET_FILE:${target}>
    COMMENT "Valgrind Memcheck is being applied to \"${target}\""
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
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  _valgrind_setup(${target})

  set(target_name ${target}-valgrind-callgrind)
  if (x_NAME)
    set(target_name ${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  unset(callgrind_options)
  if (x_TRACE_CHILDREN)
    list(APPEND callgrind_options --trace-children=yes)
    list(APPEND callgrind_options --log-file=callgrind.log.%p)
  else()
    list(APPEND callgrind_options --log-file=callgrind.log)
  endif()

  add_custom_target(${target_name}
    COMMENT "Valgrind Callgrind is running for \"${target}\" (output: \"${working_directory}/${target_name}/\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E chdir ${working_directory}/${target_name} ${Valgrind_EXECUTABLE} --tool=callgrind ${callgrind_options} $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    DEPENDS ${target}
  )

  if (NOT TARGET do-all-valgrind-callgrind)
    add_custom_target(do-all-valgrind-callgrind)
  endif()
  add_dependencies(do-all-valgrind-callgrind ${target_name})
  add_dependencies(do-all-valgrind do-all-valgrind-callgrind)
endfunction()