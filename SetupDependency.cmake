function(SetupDependency)
  set(options REQUIRED CHECK_TARGET NO_SYSTEM)
  set(oneValueArgs TARGET SUBDIR PACKAGE_NAME)
  set(multiValueArgs LIBS PATHS)
  cmake_parse_arguments(SetupDependency "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT SetupDependency_TARGET)
    message(FATAL_ERROR "Must specify a dependency target name")
  endif()

  message(STATUS "Searching for dependency ${SetupDependency_TARGET}")
  
  if(TARGET ${SetupDependency_TARGET})
    message(STATUS "Target already defined, using existing name")
    return()
  endif()

  if(NOT SetupDependency_SUBDIR)
    set(SetupDependency_SUBDIR "SetupDependency_SUBDIR_NOT_SET")
  endif()

  FOREACH(SUBDIR
      ${SetupDependency_SUBDIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/${SetupDependency_SUBDIR}
      ${CMAKE_SOURCE_DIR}/${SetupDependency_SUBDIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/third_party/${SetupDependency_TARGET}
      ${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${SetupDependency_TARGET}
      ${CMAKE_SOURCE_DIR}/third_party/${SetupDependency_TARGET}
      ${CMAKE_SOURCE_DIR}/third_party/lib${SetupDependency_TARGET}
      )
    if(EXISTS ${SUBDIR}/CMakeLists.txt)
      message(STATUS "Found a viable submodule, using code in ${SUBDIR}")
      add_subdirectory(${SUBDIR})
      if(SetupDependency_CHECK_TARGET)
        if(NOT TARGET ${SetupDependency_TARGET})
          message(FATAL_ERROR "submodule did not define the expected target")
        endif()
      endif()
      return()
    endif()
  ENDFOREACH()

  if(NO_SYSTEM)
    message(STATUS "Skipping search of system libraries because option is set")
  else()
    if(NOT SetupDependency_PACKAGE_NAME)
      set(SetupDependency_PACKAGE_NAME ${SetupDependency_TARGET})
    endif()

    find_package(${SetupDependency_PACKAGE_NAME} QUIET)
    if(${SetupDependency_PACKAGE_NAME}_FOUND)
      message(STATUS "Found a matching package")
      return()
    endif()

    if(NOT SetupDependency_LIBS)
      set(SetupDependency_LIBS "lib${SetupDependency_TARGET}.so")
    endif()

    if(SetupDependency_LIBS)
      if (SetupDependency_PATHS)
        find_library(${SetupDependency_TARGET}_LIBS NAMES ${SetupDependency_LIBS} PATHS ${SetupDependency_PATHS})
      else()
        find_library(${SetupDependency_TARGET}_LIBS NAMES ${SetupDependency_LIBS})
      endif()

      if(${SetupDependency_TARGET}_LIBS)
        message(STATUS "Found a system library ${${SetupDependency_TARGET}_LIBS} ok")
        return()
      endif()
    endif()
  endif()

  if(SetupDependency_REQUIRED)
    message(FATAL_ERROR "Could not find required dependency ${SetupDependency_TARGET}")
  else()
    message(WARNING "Could not find dependency ${SetupDependency_TARGET}")
  endif()

endfunction()
