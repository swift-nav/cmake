cmake_minimum_required(VERSION 3.2)
include("GenericFindDependency")

set(RC_ENABLE_GTEST ON CACHE BOOL "" FORCE)

GenericFindDependency(
  TARGET rapidcheck
  ADDITIONAL_TARGETS
    rapidcheck_gtest
  SYSTEM_INCLUDES
)

