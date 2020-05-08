#
# DOCUMENTATION NEEDS TO BE FILLED IN WITH ALL THE PUBLIC FACING FUNCTIONS
# AND A DESCRIPTION OF HOW TO USE IT.
#

macro(_valgrind_setup target)
  if (NOT TARGET ${target})
    message(FATAL_ERROR "Specified target \"${target}\" does not exist")
    return()
  endif()

  get_target_property(_target_type ${target} TYPE)

  if (NOT _target_type STREQUAL "EXECUTABLE")
    message(FATAL_ERROR "Specified target \"${target}\" must be an executable type")
    return()
  endif()

  if (CMAKE_CROSSCOMPILING)
    message(WARNING "Valgrind request is being ignored due to cross compiling")
    return()
  endif()

  find_package(Valgrind)

  if (NOT VALGRIND_FOUND)
    message(WARNING "Unable to generate valgrind checks for target \"${target}\" due to missing valgrind package")
    return()
  endif ()

  if (NOT TARGET do-all-valgrind-tests)
    add_custom_target(do-all-valgrind-tests)
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
    COMMAND ${CMAKE_COMMAND} -E chdir ${valgrind-reports-dir} ${VALGRIND_EXECUTABLE} --tool=memcheck ${MEMCHECK_OPTIONS} --xml=yes --xml-file=${target}.xml $<TARGET_FILE:${target}>
    COMMENT "Valgrind Memcheck is being applied to \"${target}\""
    DEPENDS ${target}
  )
  add_dependencies(do-all-valgrind-tests ${target}-memcheck)
endfunction()
