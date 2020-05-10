if (NOT GProf_FOUND)

  find_program(GProf_EXECUTABLE NAMES gprof)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GProf DEFAULT_MSG GProf_EXECUTABLE)

endif ()