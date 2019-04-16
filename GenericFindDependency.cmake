function(search_dependency_source)
  set(argOptions "")
  set(argSingleArguments "TargetName" "SourceDir")
  set(argMultiArguments "")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in search_dependency_source: ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(EXISTS "${x_SourceDir}/CMakeLists.txt")
    message(STATUS "Found ${x_TargetName} source code in ${x_SourceDir}")
    add_subdirectory(${x_SourceDir})
  else()
    message(STATUS "No ${x_TargetName} source available in ${x_SourceDir}")
  endif()
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
      if(NOT x_SourceDir)
        if(NOT x_SourcePrefix)
          set(x_SourcePrefix "vendored/lib${x_TargetName}")
        endif()

        if (NOT x_SourceSubdir)
          set(x_SourceSubdir ".")
        endif()

        set(x_SourceDir "${CMAKE_CURRENT_SOURCE_DIR}/${x_SourcePrefix}/${x_SourceSubdir}")
      endif()

      search_dependency_source(
          TargetName "${x_TargetName}"
          SourceDir "${x_SourceDir}"
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

  if(x_REQUIRED)
    message(FATAL_ERROR "Could not find dependency ${x_TargetName} in any available location")
  else()
    message(WARNING "Could not find dependency ${x_TargetName} in any available location")
  endif()
endfunction()
    
