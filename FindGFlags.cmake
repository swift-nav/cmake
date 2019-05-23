include("GenericFindDependency")
GenericFindDependency(
    TARGET gflags
    SOURCE_DIR "googleflags"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of GoogleFlags's include directories to be system includes, to avoid
  # compiler errors. The generalised version of this in GenericFindDependency won't
  # work here because we are dealing with an aliased target
  get_target_property(_aliased gflags ALIASED_TARGET)
  if(_aliased)
    get_target_property(gflags_include_directories ${_aliased} INTERFACE_INCLUDE_DIRECTORIES)
    if(gflags_include_directories)
      set_target_properties(${_aliased} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
      target_include_directories(${_aliased} SYSTEM INTERFACE ${gflags_include_directories})
    endif()
  endif()
endif()
