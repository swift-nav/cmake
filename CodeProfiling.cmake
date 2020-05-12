#
# OVERVIEW
#
# There are various technical approaches to implement profiling for an program,
# some emulate an environment and run the program on it and collect data (ex:
# Valgrind), others invoke kernel level system calls to inspect the events from
# a running program (ex: perf or dtrace). With this module, we will focus on
# what we will call "Code Profiling", which is the technique of introducing code
# during the compilation/linking that helps aggregate details about the running
# which are than recorded during the programs shutdown phase. Currently only GCC
# compilers are supported within this module.
#
# To enable any code profiling instrumentation/targets, the cmake option
# "PROFILING" needs to be set to "ON". Code that is to be profiled needs to be
# setup with the `target_code_profiling` function, without it, later on when
# the profile results come out, it won't be able to report on various statistics
# which are useful for profiling for that library/executable.
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
#     [GENERATE_REPORT]
#     [NAME target_name]
#     [WORKING_DIRECTORY working_directory]
#     [PROGRAM_ARGS arg1 arg2 ...]
#   )
#
# Call this function to create a new cmake target which will invoke the
# executable created by the specified `target` argument. For instance, if there
# was a cmake target called `unit-tests` and I invoked the function as
# `swift_add_code_profiling(unit-tests)`, it would produce the following cmake
# targets:
#
#   - unit-tests-code-profiling
#   - do-all-code-profiling
#
# The first target will run the `unit-tests` target, and generates the profile
# results to the `${CMAKE_CURRENT_BINARY_DIR}/unit-tests-code-profiling` folder.
# The results will consisted of gmon.* files. The numbers that you see
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
# The reason why this is not done by default is because the executable entry
# needs to match the process ID's executable file. If in our example
# `unit-tests` spawned off processes that call the `dr-runner` executable, the
# result folder would contain a number of gmon files, and one would have to know
# which PID corresponds to the `unit-tests` executable and which one corresponds
# to the `dr-runnner` executables. Running the `gprof` on an incorrect
# executable will generated incorrect results and will not error out. As such,
# enabling GENERATE_REPORT would mean that the target would run the gprof
# on each gmon file, assuming that it was called by the `unit-tests` executable,
# outputting the results to a gmon.*.txt file.
#
# The NAME option is there to specify the name of the new target created, this
# is quite useful if you'd like to create multiple profiling targets from a
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
# Be aware that enabling profiling for your targets can have an impact on other
# tools that ingest or work off of the library/executable. For instance if you
# attempted to run code that normally has profiling details on a Valgrind
# environment, it has the possibility of crashing.
#

option(PROFILING "Builds targets with profiling instrumentation. Currently only works with GCC Compilers" OFF)

if (PROFILING)
  if(NOT CMAKE_COMPILER_IS_GNUCXX)
    message(FATAL_ERROR "Coce profiling support is currently only available for GCC compiler")
  endif()
endif()

function(target_code_profiling target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
  endif()

  if (NOT PROFILING)
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

  if (NOT PROFILING)
    return()
  endif()

  if (CMAKE_CROSSCOMPILING)
    return()
  endif()

  if (NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  target_code_profiling(${target})

  set(target_name ${target}-code-profiling)
  if (x_NAME)
    set(target_name ${x_NAME})
  endif()

  set(working_directory ${CMAKE_CURRENT_BINARY_DIR})
  if (x_WORKING_DIRECTORY)
    set(working_directory ${x_WORKING_DIRECTORY})
  endif()

  unset(post_commands)
  if (x_GENERATE_REPORT)
    find_package(GProf)

    if (GProf_FOUND)
      list(APPEND post_commands COMMAND find ${working_directory}/${target_name} -regex ".+/gmon\\.[0-9]+$" -exec sh -c "${GProf_EXECUTABLE} $<TARGET_FILE:${target}> $0 > $0.txt" {} +)
    else()
      message(WARNING "GProf program is required to generate code profiling report")
    endif()
  endif()

  add_custom_target(${target_name}
    COMMENT "Code profiling is running for \"${target}\" (output: \"${working_directory}/${target_name}/\")"
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${working_directory}/${target_name}
    COMMAND ${CMAKE_COMMAND} -E chdir ${working_directory}/${target_name} ${CMAKE_COMMAND} -E env GMON_OUT_PREFIX=gmon $<TARGET_FILE:${target}> ${x_PROGRAM_ARGS}
    ${post_commands}
    DEPENDS ${target}
    VERBATIM
  )

  if (NOT TARGET do-all-code-profiling)
    add_custom_target(do-all-code-profiling)
  endif()
  add_dependencies(do-all-code-profiling ${target_name})
endfunction()