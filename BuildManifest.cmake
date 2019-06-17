if(NOT PROJECT_NAME)
  message(FATAL_ERROR "A project must be started before including this module")
endif()

if(TARGET "build-manifest")
  # Already set up
  return()
endif()

if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
  # Only top level projects can specify a build manifest
  message(WARNING "Not creating build manifest target, only top level projects can do this")
  return()
endif()

set(SWIFT_BUILD_MANIFEST_PY_IN "${CMAKE_CURRENT_LIST_DIR}/build-manifest.py.in" CACHE PATH "Full path to build-manifest.py.in")
set(SWIFT_BUILD_MANIFEST_PY "${CMAKE_CURRENT_BINARY_DIR}/build-manifest.py" CACHE PATH "Full path to build-manifest.py")

function(setup_build_manifest)
  if(NOT SWIFT_BUNDLED_PROJECTS)
    return()
  endif()

  configure_file(${SWIFT_BUILD_MANIFEST_PY_IN} ${SWIFT_BUILD_MANIFEST_PY})
endfunction()

function(new_included_project variable access)
  if(access STREQUAL "MODIFIED_ACCESS")
    list(APPEND SWIFT_BUNDLED_PROJECTS ${SWIFT_BUNDLED_PROJECTS} ${PROJECT_NAME})
    list(REMOVE_DUPLICATES SWIFT_BUNDLED_PROJECTS)
    set(SWIFT_BUNDLED_PROJECTS ${SWIFT_BUNDLED_PROJECTS} CACHE STRING "cmake projects included in this build" FORCE)
    setup_build_manifest()
  endif()
endfunction()

set(SWIFT_BUNDLED_PROJECTS ${PROJECT_NAME} CACHE STRING "cmake projects included in this build" FORCE)
setup_build_manifest()
variable_watch(PROJECT_NAME new_included_project)

add_custom_target(build-manifest COMMAND ${SWIFT_BUILD_MANIFEST_PY})
