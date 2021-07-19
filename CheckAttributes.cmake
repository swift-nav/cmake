function(create_check_attributes_target)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Only create for top level projects
    return()
  endif()

  set(argOption "")
  set(argSingle "")
  set(argMulti "EXCLUDE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  set(arguments "'*.[ch]'" "'*.[ch]pp'" "'*.cc'")
  foreach(excl ${x_EXCLUDE})
    list(APPEND arguments ":!:${excl}")
  endforeach()

  add_custom_target(check-attributes ALL
    ${CMAKE_CURRENT_LIST_DIR}/cmake/common/scripts/check_attributes.sh ${arguments}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )

endfunction()
