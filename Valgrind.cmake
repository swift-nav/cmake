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
  set(argOption "")
  set(argSingle "")
  set(argMulti "")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  _valgrind_setup(${target})

  add_custom_target(${target}-memcheck
    COMMAND ${VALGRIND_EXECUTABLE} --tool=memcheck $<TARGET_FILE:${target}>
    COMMENT "Valgrind Memcheck is being applied to \"${target}\""
    DEPENDS ${target}
  )
  add_dependencies(do-all-valgrind-tests ${target}-memcheck)
endfunction()