include("GenericFindDependency")
GenericFindDependency(
    TargetName gflags
    SourceDir "googleflags"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of GoogleFlags's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(gflags_include_directories gflags_nothreads_static INTERFACE_INCLUDE_DIRECTORIES)
  if(gflags_include_directories)
    set_target_properties(gflags_nothreads_static PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(gflags_nothreads_static SYSTEM INTERFACE ${gflags_include_directories})
  endif()
endif()
