include(GNUInstallDirs)
set(config_install_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
set(include_install_dir "${CMAKE_INSTALL_INCLUDEDIR}")
set(generated_dir "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(version_config "${generated_dir}/${PROJECT_NAME}ConfigVersion.cmake")
set(project_config "${generated_dir}/${PROJECT_NAME}Config.cmake")
set(TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(namespace "${PROJECT_NAME}::")

include(CMakePackageConfigHelpers)

function(setup_package_config_file)
  write_basic_package_version_file("${version_config}" COMPATIBILITY SameMajorVersion)

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/dependencies.json")
    include(JSONParser)
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/dependencies.json" json)

    sbeParseJson(dependencies json)

    set(PACKAGE_DEPENDENCIES "")
    if(dependencies.dependencies)
      set(PACKAGE_DEPENDENCIES "include(CMakeFindDependencyMacro)\n")
      foreach(i ${dependencies.dependencies})
        set(dep "dependencies.dependencies_${i}")

        unset(package)
        unset(version)
        unset(exact)
        unset(components)

        message(STATUS "setup_package_config_file: ${i} - ${${dep}.package} - ${${dep}.version} - ${${dep}.exact} - ${${dep}.components}")
        set(package "${${dep}.package}")
        if(${dep}.version)
          set(version "${${dep}.version}")
          if(${dep}.exact)
            set(exact "EXACT")
          endif()
        endif()
        if(${dep}.components)
          set(components "COMPONENTS")
          foreach(comp ${${dep}.components})
            string(CONCAT components ${components} " ${comp}")
          endforeach()
        endif()
      
        string(CONCAT PACKAGE_DEPENDENCIES ${PACKAGE_DEPENDENCIES} "find_dependency(${package} ${version} ${exact} ${components})\n")
      endforeach()
    endif()
  endif()

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PackageConfig.cmake.in")
    configure_package_config_file(
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/PackageConfig.cmake.in"
        "${project_config}"
        INSTALL_DESTINATION "${config_install_dir}"
        )
  else()
    configure_package_config_file(
        "${CMAKE_CURRENT_LIST_DIR}/PackageConfig.cmake.in"
        "${project_config}"
        INSTALL_DESTINATION "${config_install_dir}"
        )
  endif()
  
  install(
      FILES "${project_config}" "${version_config}"
      DESTINATION "${config_install_dir}"
      )
  
  install(
      EXPORT "${TARGETS_EXPORT_NAME}"
      NAMESPACE "${namespace}"
      DESTINATION "${config_install_dir}"
      EXPORT_LINK_INTERFACE_LIBRARIES
      )

endfunction()

setup_package_config_file()

function(swift_install_targets)
  set(argOption "")
  set(argSingle "")
  set(argMulti "TARGETS" "HEADER_DIRS")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_TARGETS)
    message(FATAL_ERROR "Must give at least 1 target to install")
  endif()

  set(exes)
  set(libs)

  foreach(target ${x_TARGETS})
    get_target_property(target_type ${target} TYPE)
    if("${target_type}" STREQUAL "EXECUTABLE")
      list(APPEND exes ${target})
    elseif("${target_type}" STREQUAL "STATIC_LIBRARY" OR
           "${target_type}" STREQUAL "SHARED_LIBRARY")
      list(APPEND libs ${target})
    endif()
  endforeach()

  if(libs)
    install(
        TARGETS ${libs}
        EXPORT ${TARGETS_EXPORT_NAME}
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        INCLUDES DESTINATION "${include_install_dir}"
        )
  endif()

  if(exes)
    install(
        TARGETS ${exes}
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
        )
  endif()

  if(x_HEADER_DIRS)
    install(
        DIRECTORY "${x_HEADER_DIRS}"
        DESTINATION "${include_install_dir}"
        )
  endif()
endfunction()
