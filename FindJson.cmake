include("GenericFindDependency")
GenericFindDependency(
    TargetName "nlohmann_json"
    SourceDir "json"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of Json's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(json_include_directories nlohmann_json INTERFACE_INCLUDE_DIRECTORIES)
  if(json_include_directories)
    set_target_properties(nlohmann_json PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(nlohmann_json SYSTEM INTERFACE ${json_include_directories})
  endif()
endif()
