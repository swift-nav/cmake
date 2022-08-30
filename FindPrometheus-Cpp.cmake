include("GenericFindDependency")
option(ENABLE_TESTING "Build tests" OFF)
option(ENABLE_PUSH "Build prometheus-cpp push library" OFF)
option(ENABLE_COMPRESSION "Enable gzip compression" ON)
GenericFindDependency(
    TARGET prometheus-cpp::core
    SOURCE_DIR "prometheus-cpp"
    )

# Change all of Prometheus's include directories to be system includes, to avoid
# compiler errors. The generalised version of this in GenericFindDependency won't
# work here because we are dealing with an aliased target
get_target_property(_aliased prometheus-cpp::core ALIASED_TARGET)
if(_aliased)
  get_target_property(prometheus_include_directories ${_aliased} INTERFACE_INCLUDE_DIRECTORIES)
  if(prometheus_include_directories)
    set_target_properties(${_aliased} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(${_aliased} SYSTEM INTERFACE ${prometheus_include_directories})
  endif()
endif()

# Change all of Prometheus's include directories to be system includes, to avoid
# compiler errors. The generalised version of this in GenericFindDependency won't
# work here because we are dealing with an aliased target
get_target_property(_aliased prometheus-cpp::pull ALIASED_TARGET)
if(_aliased)
  get_target_property(prometheus_include_directories ${_aliased} INTERFACE_INCLUDE_DIRECTORIES)
  if(prometheus_include_directories)
    set_target_properties(${_aliased} PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(${_aliased} SYSTEM INTERFACE ${prometheus_include_directories})
  endif()
endif()
