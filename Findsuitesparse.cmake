if (TARGET suitesparse::cholmod OR TARGET suitesparse::spqr)
  return()
endif()

include(FindPackageHandleStandardArgs)

if (APPLE)
  file(GLOB SUITESPARSE_DIRS
    /usr/local/Cellar/suitesparse/*
    /opt/homebrew/Cellar/suitesparse/*
    /usr/local/Cellar/suite-sparse/*
    /opt/homebrew/Cellar/suite-sparse/*
  )
else ()
  set(SUITESPARSE_DIRS /usr/include/suitesparse)
endif()

find_path(suitesparse_cholmod_INCLUDE_DIR
  NAMES cholmod.h
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES "suitesparse" "include/suitesparse"
)

find_path(suitesparse_spqr_INCLUDE_DIR
  NAMES SuiteSparseQR.hpp
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES "suitesparse" "include/suitesparse"
)

find_library(suitesparse_cholmod_LIBRARY
  NAMES cholmod
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES lib
)

find_library(suitesparse_spqr_LIBRARY
  NAMES spqr
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES lib
)

find_package_handle_standard_args(suitesparse REQUIRED_VARS
  suitesparse_cholmod_LIBRARY
  suitesparse_spqr_LIBRARY
  suitesparse_cholmod_INCLUDE_DIR
  suitesparse_spqr_INCLUDE_DIR
)

if (suitesparse_FOUND)
  mark_as_advanced(suitesparse_cholmod_LIBRARY)
  mark_as_advanced(suitesparse_cholmod_INCLUDE_DIR)

  add_library(suitesparse::cholmod UNKNOWN IMPORTED)
  set_target_properties(suitesparse::cholmod
      PROPERTIES
      IMPORTED_LOCATION ${suitesparse_cholmod_LIBRARY}
      INTERFACE_INCLUDE_DIRECTORIES ${suitesparse_cholmod_INCLUDE_DIR}
  )

  mark_as_advanced(suitesparse_spqr_LIBRARY)
  mark_as_advanced(suitesparse_spqr_INCLUDE_DIR)
  add_library(suitesparse::spqr UNKNOWN IMPORTED)
  set_target_properties(suitesparse::spqr
      PROPERTIES
      IMPORTED_LOCATION ${suitesparse_spqr_LIBRARY}
      INTERFACE_INCLUDE_DIRECTORIES ${suitesparse_spqr_INCLUDE_DIR}
  )
endif ()
