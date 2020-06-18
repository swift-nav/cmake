cmake_minimum_required(VERSION 3.14.0)

set(resource_name heaptrack)
set(github_repo https://github.com/KDE/heaptrack.git)

include(FetchContent)
FetchContent_Declare(
  ${resource_name}
  GIT_REPOSITORY ${github_repo}
  GIT_TAG        origin/master
)
FetchContent_MakeAvailable(${resource_name})
