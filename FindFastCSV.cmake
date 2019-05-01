include("GenericFindDependency")
GenericFindDependency(
    TargetName "fast-csv"
    SourceDir "fast-cpp-csv-parser"
    )

if(NOT CMAKE_CROSSCOMPILING OR THIRD_PARTY_INCLUDES_AS_SYSTEM)
  # Change all of fast-csv's include directories to be system includes, to avoid
  # compiler errors
  get_target_property(fast-csv_include_directories fast-csv INTERFACE_INCLUDE_DIRECTORIES)
  if(fast-csv_include_directories)
    set_target_properties(fast-csv PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "")
    target_include_directories(fast-csv SYSTEM INTERFACE ${fast-csv_include_directories})
  endif()
endif()
