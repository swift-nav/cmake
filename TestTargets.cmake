include(LanguageStandards)
include(CodeCoverage)

option(AUTORUN_TESTS "" ON)

if(NOT TARGET build-all-tests)
  add_custom_target(build-all-tests)
endif()

if(NOT TARGET do-all-tests)
  add_custom_target(do-all-tests)
endif()

if(NOT TARGET build-post-build-tests)
  add_custom_target(build-post-build-tests ALL)
endif()

if(NOT TARGET do-post-build-tests)
  add_custom_target(do-post-build-tests ALL)
endif()

function(swift_add_test_runner target)
  set(argOption "POST_BUILD")
  set(argSingle "COMMENT")
  set(argMulti "COMMAND" "DEPENDS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  add_custom_target(
      do-${target}
      COMMAND ${x_COMMAND}
      COMMENT "Running ${x_COMMENT}"
      )
  add_dependencies(do-all-tests do-${target})
  if(x_DEPENDS)
    add_dependencies(do-${target} ${x_DEPENDS})
  endif()

  if(x_POST_BUILD)
    if(AUTORUN_TESTS)
      add_custom_target(post-build-${target}
          COMMAND ${x_COMMAND}
          COMMENT "Running post build ${x_COMMENT}"
          )
    else()
      add_custom_target(post-build-${target}
        COMMAND true
        COMMENT "Skipping post build ${x_COMMENT}"
        )
    endif()
    add_dependencies(do-post-build-tests post-build-${target})
    add_dependencies(post-build-${target} build-post-build-tests)
    if(x_DEPENDS)
      add_dependencies(post-build-${target} ${x_DEPENDS})
      add_dependencies(build-post-build-tests ${x_DEPENDS})
    endif()
  endif()
endfunction()

function(swift_add_test target)
  set(argOption "PARALLEL" "POST_BUILD")
  set(argSingle "COMMENT")
  set(argMulti "SRCS" "LINK" "INCLUDE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_test unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_SRCS)
    message(FATAL_ERROR "swift_add_test must be passed at least one source file")
  endif()

  if(NOT x_COMMENT)
    set(x_COMMENT "test ${target}")
  endif()

  add_executable(${target} EXCLUDE_FROM_ALL ${x_SRCS})
  swift_set_language_standards(${target})
  if(x_INCLUDE)
    target_include_directories(${target} PRIVATE ${x_INCLUDE})
  endif()
  if(x_LINK)
    target_link_libraries(${target} PRIVATE ${x_LINK})
  endif()

  add_custom_target(
      do-${target}
      COMMAND ${target}
      COMMENT "Running ${x_COMMENT}"
      )
  add_dependencies(do-${target} ${target})
  target_code_coverage(${target} AUTO ALL)

  if(x_PARALLEL)
    add_custom_target(parallel-${target}
        COMMAND ${PROJECT_SOURCE_DIR}/third_party/gtest-parallel/gtest-parallel $<TARGET_FILE:${target}>
        COMMENT "Running ${x_COMMENT} in parallel"
        )
    add_dependencies(parallel-${target} ${target})
  endif()

  add_dependencies(build-all-tests ${target})
  add_dependencies(do-all-tests do-${target})

  if(x_POST_BUILD)
    if(AUTORUN_TESTS)
      add_custom_target(
          post-build-${target}
          COMMAND ${target}
          COMMENT "Running post build ${x_COMMENT}"
          )
    else()
      add_custom_target(
        post-build-${target}
        COMMAND true
        COMMENT "Skipping post build ${x_COMMENT}"
        )
    endif()
    add_dependencies(do-post-build-tests post-build-${target})
    add_dependencies(build-post-build-tests ${target})
    add_dependencies(post-build-${target} build-post-build-tests)
  endif()
endfunction()
