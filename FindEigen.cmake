include("GenericFindDependency")
GenericFindDependency(
  TargetName eigen
  )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of Eigen's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(eigen_include_directories eigen INTERFACE_INCLUDE_DIRECTORIES)
  if(eigen_include_directories)
    set_target_properties(eigen PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(eigen SYSTEM INTERFACE ${eigen_include_directories})
  endif()
endif()
