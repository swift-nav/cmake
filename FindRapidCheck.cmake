cmake_minimum_required(VERSION 3.2)
include("GenericFindDependency")

set(RC_ENABLE_GTEST ON CACHE BOOL "" FORCE)

GenericFindDependency(
    TARGET rapidcheck
    )

# Change all of rapidcheck's include directories to be system includes, to avoid
# compiler errors. The generalised version in GenericFindDependency isn't suitable
# in this instance.
get_target_property(rapidcheck_interface_includes rapidcheck INTERFACE_INCLUDE_DIRECTORIES)
if(rapidcheck_interface_includes)
  set_target_properties(rapidcheck PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
  target_include_directories(rapidcheck SYSTEM INTERFACE ${rapidcheck_interface_includes})
else()
  message(WARNING "No include directories in rapidcheck, this seems wrong")
endif()
unset(rapidcheck_interface_includes)

get_target_property(rapidcheck_gtest_interface_includes rapidcheck_gtest INTERFACE_INCLUDE_DIRECTORIES)
if(rapidcheck_gtest_interface_includes)
  set_target_properties(rapidcheck_gtest PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
  target_include_directories(rapidcheck_gtest SYSTEM INTERFACE ${rapidcheck_gtest_interface_includes})
else()
  message(WARNING "No include directories in rapidcheck_gtest, this seems wrong")
endif()
unset(rapidcheck_gtest_interface_includes)

