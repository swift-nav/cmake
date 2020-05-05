if (NOT VALGRIND_FOUND)

  find_program(VALGRIND_EXECUTABLE valgrind)
  set(VALGRIND_EXECUTABLE ${VALGRIND_EXECUTABLE} CACHE STRING "")

# handle the QUIETLY and REQUIRED arguments and set VALGRIND_FOUND to TRUE if
# all listed variables are TRUE
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Valgrind DEFAULT_MSG VALGRIND_EXECUTABLE)

  mark_as_advanced(VALGRIND_FOUND VALGRIND_EXECUTABLE)

endif (NOT VALGRIND_FOUND)
