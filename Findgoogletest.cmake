include("GenericFindDependency")
GenericFindDependency(
    TargetName gtest
    SourcePrefix "vendored/googletest"
    SourceSubdir "googletest"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of GoogleTest's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(gtest_include_directories gtest INTERFACE_INCLUDE_DIRECTORIES)
  if(gtest_include_directories)
    set_target_properties(gtest PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(gtest SYSTEM INTERFACE ${gtest_include_directories})
  endif()
endif()
