#
# OVERVIEW
#
# There are various technical approaches to implement profiling for any program,
# some emulate an environment, run the program on it and collect data (ex:
# Valgrind), others invoke kernel level system calls to inspect the events from
# a running program (ex: perf or dtrace). With this module, we will focus on
# what we will call "Code Profiling", which is the technique of introducing code
# during the compilation/linking that helps aggregate details about a running
# program and dumped out to a file during the programs shutdown phase. Currently
# only GCC compilers are supported within this module.
#
# To enable any code profiling instrumentation/targets, the cmake option
# "CODE_PROFILING" needs to be set to "ON". Code that is to be profiled needs to
# be setup with the `target_code_profiling` function, without it, later on when
# the profile results come out, it won't be able to report on those library
# and/or executable functions.
#
# USAGE:
#
#   target_code_profiling(<target>)
#
# Call on this function to setup the library and/or executable for profiling.
# Internally the function will simply add some compiler/linker options to the
# target.
#
#   swift_add_code_profiling(<target>
#     [NAME name]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#     [GENERATE_REPORT]
#   )
#
# Call this function to create a new cmake target which will invoke the
# executable created by the specified `target` argument. For instance, if there
# was a cmake target called `unit-tests` and I invoked the function as
# `swift_add_code_profiling(unit-tests)`, it would produce the following cmake
# targets:
#
#   - code-profiling-unit-tests
#   - do-all-code-profiling
#
# The first target will run the `unit-tests` target, and generates the profile
# results to the `${CMAKE_CURRENT_BINARY_DIR}/code-profiling-reports/unit-tests`
# folder. The results will consisted of gmon.* files. The numbers that you see
# correspond to the process ID of the running program, if you see multiple
# files, that's because the original target spawned off child processes.
# Rerunning this target will mean that any prior results will be cleared out.
#
# The second target will run the first target, as well we any other targets that
# might have been called the `swift_add_code_profiling` function, this is just a
# handy target to have to avoid explicitly running each target individually.
#
# If the `unit-tests` target depended on another cmake target which you are
# interested in, you would need to call `target_code_profiling` on that target
# to be able to see results for its code.
#
# There are a few options that are available to the function. GENERATE_REPORT is
# a simple flag to make sure that the generated gmon.* reports are translated
# into something which is readable for a user. Normally these reports are
# generated by `gprof` via the following command:
#
#   gprof <executable> <gmon file>
#
# The reason why this is not done by default is because the `executable`
# parameter needs to match the executable that launched process ID specified by
# gmon file. If in our example `unit-tests` spawned off processes that called
# the `dr-runner` executable, the results folder would contain a number of gmon
# files. One would have to know which gmon file corresponds to the `unit-tests`
# executable and which one corresponds to the `dr-runnner` executables. Running
# the `gprof` on an incorrect executable will generated incorrect results and
# will not error out. As such, when one enables GENERATE_REPORT, the function
# will run the `gprof` on each `gmon.*` file, assuming that it was called by
# the `unit-tests` executable, outputting the results to a `gmon.*.txt` file.
#
# The NAME option is there to specify the name used for the new target, this is
# quite useful if you'd like to create multiple profiling targets from a single
# cmake target executable. Continuing on with our `unit-tests` example, if the
# target was a Googletest executable, and we wanted to break the tests cases
# across different suites, we could do something like the following:
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
# This would create two targets (not including `do-all-code-profiling` in this
# list) `code-profiling-suite-1` and `code-profiling-suite-2`, each calling the
# `unit-tests` executable with different program arguments.
#
# The last option WORKING_DIRECTORY is simply there to redirect the output
# results to a different folder. By default that folder is
# `${CMAKE_CURRENT_BINARY_DIR}`, if we set that option for `suite-2` to `/tmp`,
# it would output the profiling results to `/tmp/code-profiling-reports/suite-2`.
#
# NOTES
#
# Be aware that enabling profiling for your targets can have an impact on other
# tools that ingest or work off of the library/executable. For instance if you
# attempted to run code that normally has profiling details on a Valgrind
# environment, it has the possibility of crashing.
#

option(CODE_PROFILING "Builds targets with profiling instrumentation. Currently only works with GCC Compilers" OFF)

if (CODE_PROFILING)
  if(NOT CMAKE_COMPILER_IS_GNUCXX)
    message(FATAL_ERROR "Code profiling support is currently only available for GCC compiler")
  endif()
endif()

find_package(GProf)

if (NOT GProf_FOUND)
  message(WARNING "GProf program is required to generate code profiling report")
endif()

function(target_code_profiling target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  if (NOT CODE_PROFILING)
    return()
  endif()

  target_compile_options(${target} PRIVATE -pg)
  target_link_libraries(${target} PRIVATE -pg)
endfunction()

function(swift_add_code_profiling target)
  set(argOption GENERATE_REPORT)
  set(argSingle NAME WORKING_DIRECTORY)
  set(argMulti PROGRAM_ARGS)

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  get_target_property(target_type ${target} TYPE)

  if (NOT target_type STREQUAL EXECUTABLE)
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type to register for code profiling")
  endif()

  if (NOT CODE_PROFILING)
    return()
  endif()

  if (CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  target_code_profiling(${target})

  set(target_name code-profiling-${target})
  set(report_folder ${target})
  if (x_NAME)
    set(target_name code-profiling-${x_NAME})
    set(report_folder ${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  set(reports_directory ${working_directory}/code-profiling-reports)

  unset(post_commands)
  if (GProf_FOUND AND x_GENERATE_REPORT)
    list(APPEND post_commands COMMAND find ${reports_directory}/${report_folder} -regex ".+/gmon\\.[0-9]+$" -exec sh -c "${GProf_EXECUTABLE} $<TARGET_FILE:${target}> $0 > $0.txt" {} +)
  endif()

  add_custom_target(${target_name}
    COMMENT "Code profiling is running for \"${target}\" (output: \"${reports_directory}/${report_folder}\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${reports_directory}/${report_folder}
    COMMAND ${CMAKE_COMMAND} -E chdir ${reports_directory}/${report_folder} ${CMAKE_COMMAND} -E env GMON_OUT_PREFIX=gmon $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    ${post_commands}
    DEPENDS ${target}
    VERBATIM
  )

  if (NOT TARGET do-all-code-profiling)
    add_custom_target(do-all-code-profiling)
  endif()
  add_dependencies(do-all-code-profiling ${target_name})
endfunction()