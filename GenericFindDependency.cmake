function(search_dependency_source)
  set(argOptions "")
  set(argSingleArguments "TargetName")
  set(argMultiArguments "SourceSearchPaths")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in search_dependency_source: ${x_UNPARSED_ARGUMENTS}")
  endif()

  foreach(P ${x_SourceSearchPaths})
    if(EXISTS "${P}/CMakeLists.txt")
      message(STATUS "Found ${x_TargetName} source code in ${P}")
      add_subdirectory(${P})
  
      if(NOT TARGET ${x_TargetName})
        message(WARNING "Source code in ${P} did not declare target ${x_TargetName} as was expected")
      endif()
  
      # This is very ugly, but required for some python modules, it will not last beyond this temporary solution
      if(EXISTS "${P}/include")
        set(x_${x_TargetName}_IncludeDir "${P}/include" CACHE PATH "Path to ${x_TargetName} bundled source code header files")
      endif()

      return()
    endif()
  endforeach()

  message(STATUS "No ${x_TargetName} source available in search paths")
endfunction()

function(search_dependency_system)
  set(argOptions "")
  set(argSingleArguments "TargetName" "SystemHeaderFile")
  set(argMultiArguments "SystemLibNames")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in search_dependency_system: ${x_UNPARSED_ARGUMENTS}")
  endif()

  find_path(x_${x_TargetName}_IncludeDir ${x_SystemHeaderFile})
  find_library(x_${x_TargetName}_Library NAMES ${x_SystemLibNames})

  if(NOT x_${x_TargetName}_IncludeDir OR NOT x_${x_TargetName}_Library)
    message(STATUS "Could not find ${x_TargetName} from any available sysroot path")
    return()
  endif()

  add_library(${x_TargetName} UNKNOWN IMPORTED)
  set_target_properties(${x_TargetName} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${x_${x_TargetName}_IncludeDir}")
  set_property(TARGET ${x_TargetName} APPEND PROPERTY
      IMPORTED_LOCATION "${x_${x_TargetName}_Library}")
  message(STATUS "Found ${x_TargetName} from the system at ${x_${x_TargetName}_Library}")
endfunction()

function(GenericFindDependency)
  set(argOptions "REQUIRED")
  set(argSingleArguments "TargetName" "Prefer" "SourceDir" "SourcePrefix" "SourceSubdir" "SystemHeaderFile" "SystemLibNames")
  set(argMultiArguments "Exclude")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(TARGET ${x_TargetName})
    # Target already defined, no need to do anything more
    return()
  endif()

  if(NOT x_Prefer)
    if (SWIFT_PREFERRED_DEPENDENCY_SOURCE)
      set(x_Prefer "${SWIFT_PREFERRED_DEPENDENCY_SOURCE}")
    else()
      set(x_Prefer "source")
    endif()
  endif()

  if(${x_Prefer} STREQUAL "source")
    list(APPEND x_Locations "source" "system")
  elseif(${x_Prefer} STREQUAL "system")
    list(APPEND x_Locations "system" "source")
  else()
    message(FATAL_ERROR "Unknown value for dependency location prefer: ${x_Prefer}")
  endif()

  if(x_Exclude)
    foreach(S ${x_Exclude})
      list(REMOVE_ITEM x_Locations ${S})
    endforeach()
  endif()

  if(SWIFT_EXCLUDE_DEPENDENCY_SOURCE)
    foreach(S ${SWIFT_EXCLUDE_DEPENDENCY_SOURCE})
      list(REMOVE_ITEM x_Locations ${S})
    endforeach()
  endif()

  list(LENGTH x_Locations x_NumLocations)
  if (${x_NumLocations} EQUAL 0)
    if (x_REQUIRED)
      message(FATAL_ERROR "Could not find dependency ${x_TargetName}, no locations available")
    else()
      message(WARNING "Could not find dependency ${x_TargetName}, no locations available")
      return()
    endif()
  endif()

  foreach(LOCATION ${x_Locations})
    if (${LOCATION} STREQUAL "source")
      # set defaults
      set(x_SourceSearchPaths "")
      if(NOT x_SourceDir)
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_TargetName}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${x_TargetName}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/${x_TargetName}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/lib${x_TargetName}")
      else()
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_TargetName}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${x_TargetName}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/${x_TargetName}/${x_SourceDir}")
        list(APPEND x_SourceSearchPaths "${PROJECT_SOURCE_DIR}/third_party/lib${x_TargetName}/${x_SourceDir}")
      endif()

      search_dependency_source(
          TargetName "${x_TargetName}"
          SourceSearchPaths "${x_SourceSearchPaths}"
          )
      
      if(TARGET ${x_TargetName})
        message(STATUS "Using dependency ${x_TargetName} from bundled source code")
        return()
      endif()
    else()
      if(NOT x_SystemHeaderFile)
        set(x_SystemHeaderFile "lib${x_TargetName}/${x_TargetName}.h")
      endif()

      set(x_SystemLibNames "${x_SystemLibName}" "${x_TargetName}" "lib${x_TargetName}")

      search_dependency_system(
          TargetName "${x_TargetName}"
          SystemHeaderFile "${x_SystemHeaderFile}"
          SystemLibNames "${x_SystemLibNames}"
          )

      if(TARGET ${x_TargetName})
        message(STATUS "Using dependency ${x_TargetName} from system")
        return()
      endif()
    endif()
  endforeach()

  if(x_REQUIRED OR ${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED)
    message(FATAL_ERROR "Could not find REQUIRED dependency ${x_TargetName} in any available location")
  else()
    message(WARNING "Could not find dependency ${x_TargetName} in any available location")
  endif()
endfunction()
    
