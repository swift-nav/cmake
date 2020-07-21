if(NOT Stackusage_FOUND)

  find_program(Stackusage_EXECUTABLE NAMES stackusage)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Stackusage DEFAULT_MSG Stackusage_EXECUTABLE)

  set(Stackusage_FOUND ${Stackusage_FOUND} CACHE BOOL "Flag whether Stackusage package was found")
  mark_as_advanced(Stackusage_FOUND Stackusage_EXECUTABLE)

endif()
