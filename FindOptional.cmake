include("GenericFindDependency")
GenericFindDependency(
    TargetName optional
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of Optional's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(optional_include_directories optional INTERFACE_INCLUDE_DIRECTORIES)
  if(optional_include_directories)
    set_target_properties(optional PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(optional SYSTEM INTERFACE ${optional_include_directories})
  endif()
endif()
