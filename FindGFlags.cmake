include("GenericFindDependency")
GenericFindDependency(
    TargetName gflags
    SourceDir "googleflags"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of GoogleFlags's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(_aliased gflags ALIASED_TARGET)
  if(_aliased)
    get_target_property(gflags_include_directories ${_aliased} INTERFACE_INCLUDE_DIRECTORIES)
    if(gflags_include_directories)
      set_target_properties(${_aliased} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
      target_include_directories(${_aliased} SYSTEM INTERFACE ${gflags_include_directories})
    endif()
  endif()
endif()
