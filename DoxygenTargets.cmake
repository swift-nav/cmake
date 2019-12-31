function(swift_add_doxygen target)
  find_package(Doxygen)

  if(NOT DOXYGEN_FOUND)
    message(WARNING "Unable to generate doxygen documentation for target \"${target}\" due to missing doxygen package")
    return()
  endif()

  set(argOptions)
  set(argSingleArguments CONFIGURE_FILE OUTPUT_DIRECTORY)
  set(argMultiArguments SOURCE_DIRECTORIES)

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "swift_add_doxygen unparsed arguments - ${x_UNPARSED_ARGUMENTS}")
  endif()

  set(DOXYGEN_CONFIGURE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in)
  set(DOXYGEN_SOURCE_DIRECTORIES ${PROJECT_SOURCE_DIR})
  set(DOXYGEN_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

  if(x_CONFIGURE_FILE)
    set(DOXYGEN_CONFIGURE_FILE ${x_CONFIGURE_FILE})
  endif()

  if(x_SOURCE_DIRECTORIES)
    set(DOXYGEN_SOURCE_DIRECTORIES ${x_SOURCE_DIRECTORIES})
  endif()

  if(x_OUTPUT_DIRECTORY)
    set(DOXYGEN_OUTPUT_DIRECTORY ${x_OUTPUT_DIRECTORY})
  endif()

  string(REPLACE ";" "\" \"" DOXYGEN_SOURCE_DIRECTORIES "${DOXYGEN_SOURCE_DIRECTORIES}")

  configure_file(${DOXYGEN_CONFIGURE_FILE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

  add_custom_target(${target}
    COMMAND
      ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
    DEPENDS
      ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
    COMMENT
      "Generating doxygen documentation output to \"${DOXYGEN_OUTPUT_DIRECTORY}\""
  )

endfunction()