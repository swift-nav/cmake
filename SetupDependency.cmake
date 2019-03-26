function(FindDependency)
  set(options REQUIRED CHECK_TARGET NO_SYSTEM)
  set(oneValueArgs TARGET SUBDIR PACKAGE_NAME)
  set(multiValueArgs LIBS PATHS)
  cmake_parse_arguments(FindDependency "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT FindDependency_TARGET)
    message(FATAL_ERROR "Must specify a dependency target name")
  endif()

  message(STATUS "Searching for dependency ${FindDependency_TARGET}")
  
  if(TARGET ${FindDependency_TARGET})
    message(STATUS "Target already defined, using existing name")
    return()
  endif()

  if(NOT FindDependency_SUBDIR)
    set(FindDependency_SUBDIR "FindDependency_SUBDIR_NOT_SET")
  endif()

  FOREACH(SUBDIR
      ${FindDependency_SUBDIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/${FindDependency_SUBDIR}
      ${CMAKE_SOURCE_DIR}/${FindDependency_SUBDIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/third_party/${FindDependency_TARGET}
      ${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${FindDependency_TARGET}
      ${CMAKE_SOURCE_DIR}/third_party/${FindDependency_TARGET}
      ${CMAKE_SOURCE_DIR}/third_party/lib${FindDependency_TARGET}
      )
    if(EXISTS ${SUBDIR}/CMakeLists.txt)
      message(STATUS "Found a viable submodule, using code in ${SUBDIR}")
      add_subdirectory(${SUBDIR})
      if(FindDependency_CHECK_TARGET)
        if(NOT TARGET ${FindDependency_TARGET})
          message(FATAL_ERROR "submodule did not define the expected target")
        endif()
      endif()
      return()
    endif()
  ENDFOREACH()

  if(NO_SYSTEM)
    message(STATUS "Skipping search of system libraries because option is set")
  else()
    if(NOT FindDependency_PACKAGE_NAME)
      set(FindDependency_PACKAGE_NAME ${FindDependency_TARGET})
    endif()

    find_package(${FindDependency_PACKAGE_NAME} QUIET)
    if(${FindDependency_PACKAGE_NAME}_FOUND)
      message(STATUS "Found a matching package")
      return()
    endif()

    if(NOT FindDependency_LIBS)
      set(FindDependency_LIBS "lib${FindDependency_TARGET}.so")
    endif()

    if(FindDependency_LIBS)
      if (FindDependency_PATHS)
        find_library(${FindDependency_TARGET}_LIBS NAMES ${FindDependency_LIBS} PATHS ${FindDependency_PATHS})
      else()
        find_library(${FindDependency_TARGET}_LIBS NAMES ${FindDependency_LIBS})
      endif()

      if(${FindDependency_TARGET}_LIBS)
        message(STATUS "Found a system library ${${FindDependency_TARGET}_LIBS} ok")
        return()
      endif()
    endif()
  endif()

  if(FindDependency_REQUIRED)
    message(FATAL_ERROR "Could not find required dependency ${FindDependency_TARGET}")
  else()
    message(WARNING "Could not find dependency ${FindDependency_TARGET}")
  endif()

endfunction()
