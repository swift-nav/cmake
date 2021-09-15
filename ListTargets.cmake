cmake_minimum_required(VERSION 3.7)

function(get_all_targets result exclude_third_party dir)
  get_property(subdirs DIRECTORY "${dir}" PROPERTY SUBDIRECTORIES)
  foreach(subdir IN LISTS subdirs)
    message("subdir ${subdir}")
    if(${exclude_third_party} AND ${subdir} MATCHES "^${CMAKE_SOURCE_DIR}/third_party/.*")
      message("Filtering out subdir ${subdir}")
      continue()
    endif()
    get_all_targets(${result} ${exclude_third_party} "${subdir}")
  endforeach()

  get_directory_property(sub_targets DIRECTORY "${dir}" BUILDSYSTEM_TARGETS)
  set(${result} ${${result}} ${sub_targets} PARENT_SCOPE)
endfunction()

function(swift_filter_targets out_var)
  set(argOption "")
  set(argSingle "")
  set(argMulti "TARGETS" "TYPE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments to swift_filter_targets ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_TARGETS)
    message(FATAL_ERROR "swift_filter_targets must be given a list of targets")
  endif()

  if(NOT x_TYPE)
    message(FATAL_ERROR "swift_filter_targets must be given a list of types")
  endif()

  unset(filtered_targets)
  foreach(target IN LISTS x_TARGETS)
    message("Consider ${target}")
    get_target_property(type ${target} TYPE)
    message("type ${type}")
    if(${type} IN_LIST x_TYPE)
      set(filtered_targets ${filtered_targets} ${target})
    endif()
  endforeach()

  set(${out_var} ${filtered_targets} PARENT_SCOPE)
endfunction()

function(swift_list_targets out_var)
  set(argOption "EXCLUDE_THIRD_PARTY")
  set(argSingle "")
  set(argMulti "TYPE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})
  if(x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments to swift_list_targets ${x_UNPARSED_ARGUMENTS}")
  endif()

  if(NOT x_EXCLUDE_THIRD_PARTY)
    set(x_EXCLUDE_THIRD_PARTY FALSE)
  endif()

  get_all_targets(all_targets ${x_EXCLUDE_THIRD_PARTY} ${CMAKE_CURRENT_SOURCE_DIR})
  message("all_targets: ${all_targets}")

  if(x_TYPE)
    swift_filter_targets(all_targets TARGETS ${all_targets} TYPE ${x_TYPE})
    message("all_targets 2: ${all_targets}")
  endif()

  set(${out_var} ${all_targets} PARENT_SCOPE)
endfunction()

