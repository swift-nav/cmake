#
# ArchiveUtility
#
# Archive library utility module offers the following commands to users:
#
#  * add_static_library_bundle
#
# Read through the functions documentation for mode details on what they do.
#

#
# Usage:
#   extract_static_library_bundle (<variable> <target>)
#
# Required:
#   variable: list variable where the static library dependencies will be inserted into
#   target: cmake static library target for which to extract dependencies from
#
# Given a static library target, the function will prepend onto the variable all
# the cmake static library targets that it will need to be bundled up into order
# to produce a single static library which contains everything needed for a
# person to link directly to the library without any further dependencies.
#
function (extract_static_library_bundle list_ target_)
  if (NOT TARGET ${target_})
    return ()
  endif ()

  get_target_property (target_type_ ${target_} TYPE)
  if (NOT target_type_ STREQUAL "STATIC_LIBRARY")
    return ()
  endif ()

  list (INSERT ${list_} 0 ${target_})
  set (${list_} "${${list_}}" PARENT_SCOPE)

  get_target_property (link_libraries_ ${target_} LINK_LIBRARIES)

  if (NOT link_libraries_)
    return ()
  endif ()

  foreach (link_library_ IN LISTS link_libraries_)
    extract_static_library_bundle (${list_} ${link_library_})
  endforeach ()

  list (REMOVE_DUPLICATES ${list_})
  set (${list_} "${${list_}}" PARENT_SCOPE)
endfunction ()

#
# Usage:
#   add_static_library_bundle (<target> <libraries ...> [OUTPUT_NAME name] [OUTPUT_DIRECTORY])
#
# Required
#   target: name of the cmake target to create
#   libraries: list of cmake static library which will be bundled up
#
# Optional:
#   OUTPUT_NAME: static library name to generate (defaults to ${target})
#   OUTPUT_DIRECTORY: directory where the static library bundle will be generated (defaults to ${CMAKE_CURRENT_BINARY_DIR})
#
# NOTE: this function currently is only supported on UNIX platforms
#
# Creates a cmake target which when invoked will create a static library that is
# an aggregation of the provided cmake static libraries and all its static
# library dependencies into a single static library (aka bundle).
#
# The output target resides within the OUTPUT_DIRECTORY with the file name
# "${CMAKE_STATIC_LIBRARY_PREFIX}${OUTPUT_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}"
#
function (add_static_library_bundle target)
  if (NOT UNIX)
    message (FATAL_ERROR "function currently is only supported on UNIX platforms")
  endif ()

  set (argOption "")
  set (argSingle "OUTPUT_NAME" "OUTPUT_DIRECTORY")
  set (argMulti "")

  cmake_parse_arguments (x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  set (output_name ${target})
  set (output_directory ${CMAKE_CURRENT_BINARY_DIR})
  set (libraries ${x_UNPARSED_ARGUMENTS})

  if (x_OUTPUT_NAME)
    set (output_name ${x_OUTPUT_NAME})
  endif ()

  if (x_OUTPUT_DIRECTORY)
    set (output_directory ${x_OUTPUT_DIRECTORY})
  endif ()

  set (bundle_libraries)
  foreach (library IN LISTS libraries)
    extract_static_library_bundle (bundle_libraries ${library})
  endforeach ()

  set (output_library ${CMAKE_STATIC_LIBRARY_PREFIX}${output_name}${CMAKE_STATIC_LIBRARY_SUFFIX})

  set (mri_script_dir ${CMAKE_CURRENT_BINARY_DIR}/${target}-mri)
  execute_process (COMMAND ${CMAKE_COMMAND} -E make_directory ${mri_script_dir})

  set (mri_script)
  string (APPEND mri_script "counter=1\n")
  string (APPEND mri_script "echo create ${output_library}\n\n")
  foreach (bundle_library IN LISTS bundle_libraries)
    string (APPEND mri_script "if [[ \"\$<TARGET_FILE:${bundle_library}>\" =~ [+] ]] ; then\n")
    string (APPEND mri_script "  cp \"\$<TARGET_FILE:${bundle_library}>\" \"${mri_script_dir}/${CMAKE_STATIC_LIBRARY_PREFIX}mri_\${counter}${CMAKE_STATIC_LIBRARY_SUFFIX}\"\n")
    string (APPEND mri_script "  echo addlib ${mri_script_dir}/${CMAKE_STATIC_LIBRARY_PREFIX}mri_\${counter}${CMAKE_STATIC_LIBRARY_SUFFIX}\n")
    string (APPEND mri_script "  counter=$((counter + 1))\n")
    string (APPEND mri_script "else\n")
    string (APPEND mri_script "  echo addlib \$<TARGET_FILE:${bundle_library}>\n")
    string (APPEND mri_script "fi\n\n")
  endforeach()
  string (APPEND mri_script "echo save\n")
  string (APPEND mri_script "echo end")

  set (mri_script_file ${mri_script_dir}/script.mri.sh)

  file (GENERATE
    OUTPUT ${mri_script_file}
    CONTENT "${mri_script}"
    CONDITION 1
  )

  add_custom_command (
    COMMAND bash ${mri_script_file} | ${CMAKE_AR} -M
    COMMAND_EXPAND_LISTS
    OUTPUT
      ${output_directory}/${output_library}
    WORKING_DIRECTORY
      ${output_directory}
    DEPENDS
      ${bundle_libraries}
  )

  add_custom_target (${target} ALL
    DEPENDS ${output_directory}/${output_library}
  )
endfunction ()