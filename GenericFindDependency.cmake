#
# A generic cmake function to search for a dependency from several places and
# include in the build system as appropriate
#
# Dependencies can be picked up either from bundled source code, usually a git
# submodule located in the 'third_party' directory, or from libraries installed
# in the host system or cross compiling sysroot.
#
# By default dependencies are first sought in bundled source code, and if not
# found from the system libraries. This default behaviour can be controlled by 
# several options
#
# EXCLUDE - can be used to disable searching in a particular location. Valid
#   arguments are 'source' and 'system'
# PREFER - used to override the default search location. Valid arguments are
#   'source' and 'system'. If not specified defaults to 'source'
#
# Similar options can be specified on the command line as well.
# SWIFT_PREFERRED_DEPENDENCY_SOURCE takes the same arguments as above but
# will apply globally across the entire build tree at configure time. For example
#
# cmake -DSWIFT_PREFERRED_DEPENDENCY_SOURCE=system <path>
#
# will try to use depenedencies from the system libraries rather than bundled
# source code.
#
# If the dependency is picked up from the system libraries this function will
# create an interface target which can be used to link in to any other target.
#
# The options "SYSTEM_HEADER_FILE" and "SYSTEM_LIB_NAMES" will be passed verbatim
# to the cmake functions find_header() and find_library() to search all the 
# correct system locations.
#
# When using bundled source code the function will search several default locations
# under '${CMAKE_CURRENT_SOURCE_DIR}/third_party' based on the package and target
# names. The search location can be controlled by the "SOURCE_DIR" parameter
#
# The target name can be controlled by the option "TARGET". When using 
# bundled source code this is used to verify the target was created properly
# after calling add_subdirectory
#
# Passing the option SYSTEM_INCLUDES will rewrite the target include directories
# so that they are marked as system headers. This will usually be passed to
# the compiler as an command line option as decided by cmake. Be careful with
# this option, it will supress warning which might otherwise be helpful.
#
# The option REQUIRED can be passed which will cause this function to fail
# if the dependency was not found for any reason.
#
# Example: FindGoogletest.cmake
#
# GenericFindDependency(
#    TARGET gtest
#    SOURCE_DIR "googletest"
#    SYSTEM_INCLUDES
#    )
#

function(search_dependency_source)
  set(argOptions "")
  set(argSingleArguments "TARGET")
  set(argMultiArguments "SOURCE_SEARCH_PATHS")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in search_dependency_source: ${x_UNPARSED_ARGUMENTS}")
  endif()

  foreach(P ${x_SOURCE_SEARCH_PATHS})
    if(EXISTS "${P}/CMakeLists.txt")
      message(STATUS "Found ${x_TARGET} source code in ${P}")
      add_subdirectory(${P})
  
      if(NOT TARGET ${x_TARGET})
        message(WARNING "Source code in ${P} did not declare target ${x_TARGET} as was expected")
      endif()
  
      # This is very ugly, but required for some python modules, it will not last beyond this temporary solution
      if(EXISTS "${P}/include")
        set(x_${x_TARGET}_IncludeDir "${P}/include" CACHE PATH "Path to ${x_TARGET} bundled source code header files")
      endif()

      return()
    endif()
  endforeach()

  message(STATUS "No ${x_TARGET} source available in search paths")
endfunction()

function(search_dependency_system)
  set(argOptions "")
  set(argSingleArguments "TARGET" "SYSTEM_HEADER_FILE")
  set(argMultiArguments "SYSTEM_LIB_NAMES")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected extra arguments in search_dependency_system: ${x_UNPARSED_ARGUMENTS}")
  endif()

  find_path(x_${x_TARGET}_IncludeDir ${x_SYSTEM_HEADER_FILE})
  find_library(x_${x_TARGET}_Library NAMES ${x_SYSTEM_LIB_NAMES})

  if(NOT x_${x_TARGET}_IncludeDir OR NOT x_${x_TARGET}_Library)
    message(STATUS "Could not find ${x_TARGET} from any available sysroot path")
    return()
  endif()

  add_library(${x_TARGET} UNKNOWN IMPORTED)
  set_target_properties(${x_TARGET} PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${x_${x_TARGET}_IncludeDir}")
  set_property(TARGET ${x_TARGET} APPEND PROPERTY
      IMPORTED_LOCATION "${x_${x_TARGET}_Library}")
  message(STATUS "Found ${x_TARGET} from the system at ${x_${x_TARGET}_Library}")
endfunction()

# To be called from GenericFindDependency
#
# Create the variable which will contain a list of possible search locations sorted
# by order of preference
#
# This is a macro so all input and output variable exist in the context of the caller
#
# This macro will return(), ie cause the caller to return, if there are no available locations.
# It will raise a fatal error if unknown values are specified for any of the input parameters.
#
# Inputs: 
# - x_PREFER - Parameter to GenericFindDependency, preferred location as defined by the project
# - SWIFT_PREFERRED_DEPENDENCY_SOURCE - Global user preference, defined on the command line
# - x_EXCLUDE - List of sources to exclude from consideration
# - SWIFT_EXCLUDE_DEPENDENCY_SOURCE - Global user exclude list, defined on the command line
#
# Outputs:
# - x_Locations - List of locations to search for the dependency
# - x_NumLocations - Length of x_Locations
#
macro(setup_search_locations)
  if(NOT x_PREFER)
    if (SWIFT_PREFERRED_DEPENDENCY_SOURCE)
      set(x_PREFER "${SWIFT_PREFERRED_DEPENDENCY_SOURCE}")
    else()
      set(x_PREFER "source")
    endif()
  endif()

  if(${x_PREFER} STREQUAL "source")
    list(APPEND x_Locations "source" "system")
  elseif(${x_PREFER} STREQUAL "system")
    list(APPEND x_Locations "system" "source")
  else()
    message(FATAL_ERROR "Unknown value for dependency location prefer: ${x_PREFER}")
  endif()

  if(x_EXCLUDE)
    foreach(S ${x_EXCLUDE})
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
      message(FATAL_ERROR "Could not find dependency ${x_TARGET}, no locations available")
    else()
      message(WARNING "Could not find dependency ${x_TARGET}, no locations available")
      return()
    endif()
  endif()
endmacro()

#
# To be called from GenericFindDependency
#
# Creates a list of paths to be searched for source code for the dependency
#
# This is a macro, all input and output variables exist in the context of the caller
#
# If a source dir path is not explicitly specified this macro will generate a list of
# probable locations for the dependency source code. It outputs a list of absolute
# paths to be searched
#
# Inputs:
# - x_SOURCE_DIR - Parameter to GenericFindDependency, appened to the generated search paths
#
# Outputs:
# - x_SOURCE_SEARCH_PATHS - A list of paths to be searched for source code
#
macro(create_source_search_paths)
  # set defaults
  set(x_SOURCE_SEARCH_PATHS "")
  if(NOT x_SOURCE_DIR)
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_TARGET}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${x_TARGET}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/${x_TARGET}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/lib${x_TARGET}")
  else()
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/${x_TARGET}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${CMAKE_CURRENT_SOURCE_DIR}/third_party/lib${x_TARGET}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/${CMAKE_FIND_PACKAGE_NAME}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/${x_TARGET}/${x_SOURCE_DIR}")
    list(APPEND x_SOURCE_SEARCH_PATHS "${PROJECT_SOURCE_DIR}/third_party/lib${x_TARGET}/${x_SOURCE_DIR}")
  endif()
endmacro()

#
# Helper function to mark the specified target's include directories as system. This is
# then passed to the compiler which will surpress warnings generated from any header file
# included by this path. Use with care
#
# Should only be called from GenericFindDependency
#
function(mark_target_as_system_includes TARGET)
  get_target_property(directories ${x_TARGET} INTERFACE_INCLUDE_DIRECTORIES)
  if(directories)
    message(STATUS "Marking ${x_TARGET} include directories as system")
    set_target_properties(${x_TARGET} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(${x_TARGET} SYSTEM INTERFACE ${directories})
  endif()
endfunction()

function(GenericFindDependency)
  set(argOptions "REQUIRED" "SYSTEM_INCLUDES")
  set(argSingleArguments "TARGET" "PREFER" "SOURCE_DIR" "SYSTEM_HEADER_FILE" "SYSTEM_LIB_NAMES")
  set(argMultiArguments "EXCLUDE")

  cmake_parse_arguments(x "${argOptions}" "${argSingleArguments}" "${argMultiArguments}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unexpected unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(TARGET ${x_TARGET})
    # Target already defined, no need to do anything more
    return()
  endif()

  # Generate a list of locations to search for the dependency in order of preference
  setup_search_locations()

  foreach(LOCATION ${x_Locations})
    if (${LOCATION} STREQUAL "source")
      # Try looking for bundled source code

      # Set up search locations for source code
      create_source_search_paths()

      # Look for a suitably named directory which contains a CMakeLists.txt, try to add it
      search_dependency_source(
          TARGET "${x_TARGET}"
          SOURCE_SEARCH_PATHS "${x_SOURCE_SEARCH_PATHS}"
          )
      
      # If the expected target was created we have succeeded
      if(TARGET ${x_TARGET})
        message(STATUS "Using dependency ${x_TARGET} from bundled source code")
        break()
      endif()
    else()
      # Try looking for a header file and library in the system paths

      if(NOT x_SYSTEM_HEADER_FILE)
        # Use a sensible header file name if not explicitly set
        set(x_SYSTEM_HEADER_FILE "lib${x_TARGET}/${x_TARGET}.h")
      endif()

      # Look for common library naming patterns
      set(x_SYSTEM_LIB_NAMES "${x_SystemLibName}" "${x_TARGET}" "lib${x_TARGET}")

      # Search either system libraries or sysroot, this is handled by cmake itself
      search_dependency_system(
          TARGET "${x_TARGET}"
          SYSTEM_HEADER_FILE "${x_SYSTEM_HEADER_FILE}"
          SYSTEM_LIB_NAMES "${x_SYSTEM_LIB_NAMES}"
          )

      # If the target was found we have succeeded
      if(TARGET ${x_TARGET})
        message(STATUS "Using dependency ${x_TARGET} from system")
        break()
      endif()
    endif()
  endforeach()

  # Final validation that the target was properly created from some source
  if(TARGET ${x_TARGET})
    if(x_SYSTEM_INCLUDES)
      if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
        mark_target_as_system_includes(${x_TARGET})
      endif()
    endif()
  else()
    # Target not found in any location
    if(x_REQUIRED OR ${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED)
      message(FATAL_ERROR "Could not find REQUIRED dependency ${x_TARGET} in any available location")
    else()
      message(WARNING "Could not find dependency ${x_TARGET} in any available location")
    endif()
  endif()
endfunction()
    
