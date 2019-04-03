if(TARGET gnss_converters)
  return()
endif()

set(SUBMOD_PATH "${PROJECT_SOURCE_DIR}/third_party/gnss-converters/c")
if(FINDGNSS_CONVERTERS_SUBMOD_PATH)
  set(SUBMOD_PATH ${FINDGNSS_CONVERTERS_SUBMOD_PATH})
endif()

if(EXISTS "${SUBMOD_PATH}/CMakeLists.txt")
  message(STATUS "Found gnss-converters source in ${SUBMOD_PATH}")
  add_subdirectory("${SUBMOD_PATH}")
  if(NOT TARGET gnss_converters)
    message(FATAL_ERROR "Including directory ${SUBMOD_PATH} did not generate target gnss-converters as expected")
  endif()
  return()
endif()

find_path(GNSS_CONVERTERS_INCLUDE_DIR libgnss-converters/nmea.h)

set(GNSS_CONVERTERS_LIB_NAMES ${GNSS_CONVERTERS_LIB_NAMES} gnss_converters libgnss_converters)
find_library(GNSS_CONVERTERS_LIBRARY NAMES ${GNSS_CONVERTERS_LIB_NAMES})

include(${CMAKE_ROOT}/Modules/FindPackageHandleStandardArgs.cmake)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(gnss_converters DEFAULT_MSG GNSS_CONVERTERS_LIBRARY GNSS_CONVERTERS_INCLUDE_DIR)

if(GNSS_CONVERTERS_FOUND)
  add_library(gnss_converters UNKNOWN IMPORTED)
  set_target_properties(gnss_converters PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "${SBP_INCLUDE_DIRS}")

  set_property(TARGET gnss_converters APPEND PROPERTY
      IMPORTED_LOCATION "${GNSS_CONVERTERS_LIBRARY}")
endif()


