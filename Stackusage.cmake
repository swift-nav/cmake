cmake_minimum_required(VERSION 3.11.0)

set(resource_name stackusage)
set(github_repo https://github.com/d99kris/stackusage.git)

include(FetchContent)
FetchContent_Declare(
  ${resource_name}
  GIT_REPOSITORY ${github_repo}
  GIT_TAG        origin/master
)
FetchContent_GetProperties(${resource_name})
if(NOT ${resource_name}_POPULATED)
  FetchContent_Populate(${resource_name})
  add_subdirectory(${${resource_name}_SOURCE_DIR} ${${resource_name}_BINARY_DIR})
endif()

