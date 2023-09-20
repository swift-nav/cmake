if (TARGET suitesparse::suitesparse)
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
  file(GLOB SUITESPARSE_DIRS
    /usr/include/suitesparse/*
  )
endif()

find_path(suitesparse_INCLUDE_DIR
  NAMES SuiteSparseQR.hpp cholmod.h
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES include
)

find_library(suitesparse_LIBRARY
  NAMES spqr cholmod
  HINTS ${SUITESPARSE_DIRS}
  PATH_SUFFIXES lib
)

find_package_handle_standard_args(suitesparse REQUIRED_VARS
    suitesparse_LIBRARY
    suitesparse_INCLUDE_DIR
)

if (suitesparse_FOUND)
  mark_as_advanced(suitesparse_LIBRARY)
  mark_as_advanced(suitesparse_INCLUDE_DIR)

  add_library(suitesparse::suitesparse UNKNOWN IMPORTED)
  set_target_properties(suitesparse::suitesparse
      PROPERTIES
      IMPORTED_LOCATION ${suitesparse_LIBRARY}
      INTERFACE_INCLUDE_DIRECTORIES ${suitesparse_INCLUDE_DIR}
  )
endif ()
