function(swift_setup_clang_tidy)
  set(argOption "")
  set(argSingle "SCRIPT")
  set(argMulti "CLANG_TIDY_NAMES" "TARGETS" "FILES")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  set(top_level_project OFF)
  if(${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    set(top_level_project ON)
  endif()

  option(${PROJECT_NAME}_ENABLE_CLANG_TIDY "Enable auto-linting of code using code-tidy" ${top_level_project})

  if(NOT ${PROJECT_NAME}_ENABLE_CLANG_TIDY)
    message(STATUS "${PROJECT_NAME} clang-tidy support is DISABLED")
    return()
  endif()

  set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Export compile commands" FORCE)

  if(NOT x_CLANG_TIDY_NAMES)
    set(x_CLANG_TIDY_NAMES 
        clang-tidy60 clang-tidy-6.0
        clang-tidy40 clang-tidy-4.0
        clang-tidy39 clang-tidy-3.9
        clang-tidy38 clang-tidy-3.8
        clang-tidy37 clang-tidy-3.7
        clang-tidy36 clang-tidy-3.6
        clang-tidy35 clang-tidy-3.5
        clang-tidy34 clang-tidy-3.4
        clang-tidy
       )
  endif()
  find_program(CLANG_TIDY NAMES ${x_CLANG_TIDY_NAMES})

  if("${CLANG_TIDY}" STREQUAL "CLANG_TIDY-NOTFOUND")
    message(WARNING "Could not find appropriate clang-tidy, target disabled")
    return()
  endif()

  message(STATUS "Using ${CLANG_TIDY}")
  set(${PROJECT_NAME}_CLANG_TIDY ${CLANG_TIDY} CACHE STRING "Absolute path to clang-tidy for ${PROJECT_NAME}")

  if(x_SCRIPT)
    set(custom_scripts ${x_SCRIPT})
  else()
    set(custom_scripts "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-tidy.sh" "${CMAKE_CURRENT_SOURCE_DIR}/scripts/clang-tidy.bash")
  endif()

  foreach(script ${custom_scripts})
    if(EXISTS ${script})
      message(STATUS "Initialising clang tidy target for ${PROJECT_NAME} using existing script in ${script}")
      if(top_level_project)
        add_custom_target(
            clang-tidy-all
            COMMAND ${script} all
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            )
      endif()
      return()
    endif()

    if(x_SCRIPT)
      # Was passed a script name but it doesn't exist
      message(WARNING "Specified clang-tidy script ${x_SCRIPT} doesn't exist")
      return()
    endif()
  endforeach()

  if(x_TARGETS)
    foreach(target ${x_TARGETS})
      if(NOT TARGET ${target})
        message(WARNING "clang-tidy enabled for non-existent target ${target}")
        continue()
      endif()

      # Extract the list of source files from the target and convert to absolute paths
      set(target_srcs "")
      set(abs_target_srcs "")
      get_target_property(target_srcs ${target} SOURCES)
      foreach(file ${target_srcs})
        if(${file} MATCHES ".*\\.h$")
          list(REMOVE_ITEM target_srcs ${file})
        endif()
      endforeach()
  
      list(REMOVE_DUPLICATES target_srcs)
  
      get_target_property(target_dir ${target} SOURCE_DIR)
      foreach(file ${target_srcs})
        get_filename_component(abs_file ${file} ABSOLUTE BASE_DIR ${target_dir})
        list(APPEND abs_target_srcs ${abs_file})
      endforeach()
  
      if(abs_target_srcs)
        list(APPEND all_srcs ${abs_target_srcs})
      else()
        message(WARNING "Target ${target} does not have any lintable sources")
      endif()
    endforeach()
  elseif(x_FILES)
    foreach(pattern ${x_FILES})
      set(files "")
      file(GLOB files ${pattern})
      list(APPEND all_srcs ${files})
    endforeach()
  else()
    message(FATAL_ERROR "Must specify either SCRIPT, FILES, or TARGETS in order to set up clang-tidy")
  endif()

  if(all_srcs)
    if(top_level_project)
      list(REMOVE_DUPLICATES all_srcs)
      add_custom_target(
          clang-tidy-all
          COMMAND ${${PROJECT_NAME}_CLANG_TIDY} -p ${CMAKE_BINARY_DIR} --export-fixes=${CMAKE_CURRENT_SOURCE_DIR}/fixes.yaml ${all_srcs}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          )
    endif()
  else()
    message(WARNING "Project ${PROJECT_NAME} did not enable linting for any files/targets")
  endif()
endfunction()
