if(NOT Bloaty_FOUND)

  find_program(Bloaty_EXECUTABLE bloaty)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Bloaty DEFAULT_MSG Bloaty_EXECUTABLE)

  set(Bloaty_FOUND ${Bloaty_FOUND} CACHE BOOL "Flag whether Bloaty package was found")
  mark_as_advanced(Bloaty_FOUND Bloaty_EXECUTABLE)

endif()
