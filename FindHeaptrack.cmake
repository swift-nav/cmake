if(NOT Heaptrack_FOUND)

  find_program(Heaptrack_EXECUTABLE NAMES heaptrack)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Heaptrack DEFAULT_MSG Heaptrack_EXECUTABLE)

  set(Heaptrack_FOUND ${Heaptrack_FOUND} CACHE BOOL "Flag whether Heaptrack package was found")
  mark_as_advanced(Heaptrack_FOUND Heaptrack_EXECUTABLE)

endif()
