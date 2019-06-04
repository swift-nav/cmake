macro(parse_dependency_file)
  unset(dependencies_valid)
  unset(dependencies)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/dependencies.json")
    include(JSONParser)
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/dependencies.json" json)

    sbeParseJson(raw json)

    foreach(i ${raw.dependencies})
      set(dep "raw.dependencies_${i}")

      unset(package)
      unset(version)
      unset(exact)
      unset(components)
      unset(required)

      message(STATUS "SwiftDependencyHelpers: ${i} - ${${dep}.package} - ${${dep}.version} - ${${dep}.exact} - ${${dep}.components} - ${${dep}.required}")

      set(dependencies_${i}.package "${${dep}.package}")
      if(${dep}.version)
        set(dependencies_${i}.version "${${dep}.version}")
        if(${dep}.exact)
          set(dependencies_${i}.exact "EXACT")
        endif()
      endif()
      if(${dep}.components)
        set(dependencies_${i}.components "COMPONENTS")
        string(REPLACE " " ";" comp_list ${${dep}.components})
        foreach(comp ${comp_list})
          list(APPEND dependencies_${i}.components ${comp})
        endforeach()
      endif()
      if(${dep}.required)
        set(dependencies_${i}.required "REQUIRED")
      endif()

      list(APPEND dependencies ${i})

      message(STATUS "... ${dependencies_${i}.package} - ${dependencies_${i}.version} - ${dependencies_${i}.exact} - ${dependencies_${i}.required} - ${dependencies_${i}.components}")

    endforeach()
    sbeClearJson(raw)
    set(dependencies_valid TRUE)
  endif()
endmacro()

function(find_dependencies)
  unset(dependencies_valid)
  parse_dependency_file()

  if(dependencies_valid)
    
    foreach(i ${dependencies})
      set(dep "dependencies_${i}")
          message(STATUS "${i} - ${${dep}.package} - ${${dep}.version} - ${${dep}.exact} - ${${dep}.required} - ${${dep}.components}")
      find_package(
          ${${dep}.package}
          ${${dep}.version}
          ${${dep}.exact}
          ${${dep}.required}
          ${${dep}.components}
          )
    endforeach()
  endif()
endfunction()

