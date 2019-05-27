function(swift_setup_clang_tidy)
  set(argOption "")
  set(argSingle "SCRIPT")
  set(argMulti "CLANG_TIDY_NAMES" "TARGETS")

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
      add_custom_target(
          clang-tidy-${PROJECT_NAME}
          COMMAND ${script}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          )
      if(top_level_project)
        add_custom_target(
            clang-tidy-all
            COMMAND ${script}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            )
      endif()
      return()
    endif()
  endforeach()

  foreach(target ${${PROJECT_NAME}_clang_tidy_targets})
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
      add_custom_target(
          clang-tidy-${target}
          COMMAND echo ${${PROJECT_NAME}_CLANG_TIDY} -p ${CMAKE_BINARY_DIR} --export-fixes=${CMAKE_CURRENT_SOURCE_DIR}/fixes-${target}.yaml ${abs_target_srcs}
          WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
          )
      list(APPEND all_srcs ${abs_target_srcs})
    else()
      message(WARNING "Target ${target} does not have any lintable sources")
    endif()
  endforeach()

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
    message(WARNING "Project ${PROJECT_NAME} did not enable linting for any targets")
  endif()
endfunction()

function(swift_target_enable_clang_tidy TARGET)
  if(NOT TARGET ${TARGET})
    message(WARNING "Trying to enable clang-tidy for ${TARGET} which doesn't exist")
    return()
  endif()

  list(APPEND ${PROJECT_NAME}_clang_tidy_targets ${TARGET})
  set(${PROJECT_NAME}_clang_tidy_targets ${${PROJECT_NAME}_clang_tidy_targets} CACHE INTERNAL "List of targets in ${PROJECT_NAME} to auto-lint with clang-tidy")
endfunction()
