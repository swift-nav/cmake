if (NOT GProf_FOUND)

  find_program(GProf_EXECUTABLE NAMES gprof)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(GProf DEFAULT_MSG GProf_EXECUTABLE)

  set(GProf_FOUND ${GProf_FOUND} CACHE BOOL "Flag whether GProf package was found")
  mark_as_advanced(GProf_FOUND GProf_EXECUTABLE)

endif ()