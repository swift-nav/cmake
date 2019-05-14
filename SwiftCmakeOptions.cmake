function(swift_create_project_options)
  set(argOptions "")
  set(argSingleArguments "PROJECT" "TESTS" "TEST_LIBS" "DOCS" "EXAMPLES")
  set(argMultiArguments "TEST_PACKAGES")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in swift_create_project_options: ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_PROJECT)
    set(x_PROJECT ${PROJECT_NAME})
  endif()

  if(NOT x_TESTS)
    set(x_TESTS ON)
  endif()

  if(NOT x_TEST_LIBS)
    set(x_TEST_LIBS ON)
  endif()

  if(NOT x_DOCS)
    set(x_DOCS ON)
  endif()

  if(NOT x_EXAMPLES)
    set(x_EXAMPLES ON)
  endif()

  # Force test libs to be compiled if we are doing unit tests at all
  if(x_TESTS)
    set(x_TEST_LIBS ON)
  endif()

  if(NOT x_SKIP_CROSS_COMPILING_CHECK)
    if(CMAKE_CROSSCOMPILING)
      # Don't compile any test stuff if we are cross compiling
      message(STATUS "Skipping unit tests because we are cross compiling")
      set(x_TESTS OFF)
      set(x_TEST_LIBS OFF)
    endif()
  endif()

  if(x_TESTS OR x_TEST_LIBS)
    foreach(P "${x_TEST_PACKAGES}")
      find_package(${P})
      # Annoyingly, different test packages have different ways of reporting they were found
      set(found FALSE)
      if(${P} STREQUAL "Check" AND CHECK_FOUND)
        set(found TRUE)
      elseif(${P} STREQUAL "Googletest" AND TARGET gtest)
        set(found TRUE)
      endif()
      if(NOT found)
        message(STATUS "Disable tests because dependency ${P} was not found")
        set(x_TESTS OFF)
        set(x_TEST_LIBS OFF)
      endif()
    endforeach()
  endif()

  option(${x_PROJECT}_BUILD_TEST_LIBS "Enable build of test libraries for ${x_PROJECT}" ${x_TEST_LIBS})
  option(${x_PROJECT}_BUILD_TESTS "Enable build of unit tests for ${x_PROJECT}" ${x_TESTS})
  option(${x_PROJECT}_BUILD_DOCS "Enable build of documentation for ${x_PROJECT}" ${x_DOCS})
  option(${x_PROJECT}_BUILD_EXAMPLES "Enable build of example code for ${x_PROJECT}" ${x_EXAMPLES})

  if(NOT ${x_PROJECT}_BUILD_TEST_LIBS)
    message(STATUS "${x_PROJECT} test libraries are DISABLED")
  endif()

  if(NOT ${x_PROJECT}_BUILD_TESTS)
    message(STATUS "${x_PROJECT} unit tests are DISABLED")
  endif()

  if(NOT ${x_PROJECT}_BUILD_DOCS)
    message(STATUS "${x_PROJECT} documentation is DISABLED")
  endif()

  if(NOT ${x_PROJECT}_BUILD_EXAMPLES)
    message(STATUS "${x_PROJECT} examples are DISABLED")
  endif()

endfunction()
  
