include("GenericFindDependency")
option(YAML_CPP_BUILD_TOOLS "Enable testing and parse tools" OFF)
option(YAML_CPP_BUILD_CONTRIB "Enable contrib stuff in library" OFF)
GenericFindDependency(
    TargetName "yaml-cpp"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of Yaml-Cpp's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(yaml-cpp_include_directories yaml-cpp INTERFACE_INCLUDE_DIRECTORIES)
  if(yaml-cpp_include_directories)
    set_target_properties(yaml-cpp PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(yaml-cpp SYSTEM INTERFACE ${yaml-cpp_include_directories})
  endif()
endif()
