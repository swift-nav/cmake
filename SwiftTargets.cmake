include(CodeCoverage)
include(CompileOptions)
include(LanguageStandards)
include(TestTargets)

cmake_policy(SET CMP0007 NEW)  # new behaviour list command no longer ignores empty elements

macro(swift_collate_arguments prefix name)
  set(exclusion_list ${ARGN})
  set(${name}_args "")

  foreach(arg IN LISTS ${name}_option)
    list(FIND exclusion_list "${arg}" index)
    if (NOT index EQUAL -1)
      continue()
    endif()
    if (${prefix}_${arg})
      list(APPEND ${name}_args ${arg})
    endif()
  endforeach()

  foreach(arg IN LISTS ${name}_single ${name}_multi)
    list(FIND exclusion_list "${arg}" index)
    if (NOT index EQUAL -1)
      continue()
    endif()
    if (${prefix}_${arg})
      list(APPEND ${name}_args ${arg} ${${prefix}_${arg}})
    endif()
  endforeach()
endmacro()

function(swift_add_target target type)
  set(this_option INTERFACE STATIC SHARED MODULE)
  set(this_single "")
  set(this_multi SOURCES)

  set(compile_options_option WARNING NO_EXCEPTIONS EXCEPTIONS NO_RTTI RTTI)
  set(compile_options_single "")
  set(compile_options_multi ADD_COMPILE_OPTIONS REMOVE_COMPILE_OPTIONS)

  set(language_standards_option C_EXTENSIONS_ON)
  set(language_standards_single C_STANDARD CXX_STANDARD)
  set(language_standards_multi "")

  set(arg_option ${this_option} ${compile_options_option} ${language_standards_option})
  set(arg_single ${this_single} ${compile_options_single} ${language_standards_single})
  set(arg_multi ${this_multi} ${compile_options_multi} ${language_standards_multi})
  list(REMOVE_ITEM arg_option "")
  list(REMOVE_ITEM arg_single "")
  list(REMOVE_ITEM arg_multi "")

  cmake_parse_arguments(x "${arg_option}" "${arg_single}" "${arg_multi}" ${ARGN})

  if (x_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Unparsed arguments ${x_UNPARSED_ARGUMENTS}")
  endif()

  swift_collate_arguments(x compile_options ADD_COMPILE_OPTIONS REMOVE_COMPILE_OPTIONS)
  swift_collate_arguments(x language_standards C_STANDARD CXX_STANDARD)

  if (x_ADD_COMPILE_OPTIONS)
    list(APPEND compile_options_args ADD ${x_ADD_COMPILE_OPTIONS})
  endif()
  if (x_REMOVE_COMPILE_OPTIONS)
    list(APPEND compile_options_args REMOVE ${x_REMOVE_COMPILE_OPTIONS})
  endif()

  if (x_C_STANDARD)
    list(APPEND language_standards_args C ${x_C_STANDARD})
  endif()
  if (x_CXX_STANDARD)
    list(APPEND language_standards_args CXX ${x_CXX_STANDARD})
  endif()

  if (x_INTERFACE)
    if (x_SOURCES)
      message(FATAL_ERROR "Can't create interface target with source files")
    endif()
    if (x_STATIC OR x_SHARED OR x_MODULE)
      message(FATAL_ERROR "Can't create interface target with a specified library type (STATIC/SHARED/MODULE)")
    endif()
  endif()

  set(library_type)
  if (x_STATIC)
    list(APPEND library_type STATIC)
  endif()
  if (x_SHARED)
    list(APPEND library_type SHARED)
  endif()
  if (x_MODULE)
    list(APPEND library_type MODULE)
  endif()

  if (type STREQUAL "executable")
    add_executable(${target} ${x_SOURCES})
  elseif(type STREQUAL "library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
  elseif(type STREQUAL "test_library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
  elseif(type STREQUAL "tool")
    add_executable(${target} ${x_SOURCES})
  elseif(type STREQUAL "tool_library")
    if (x_INTERFACE)
      add_library(${target} INTERFACE)
    else()
      add_library(${target} ${library_type} ${x_SOURCES})
    endif()
  else()
    message(FATAL_ERROR "Unknown Swift target type ${type}")
  endif()

  if (NOT x_INTERFACE)
    swift_set_compile_options(${target} ${compile_options_args})
    swift_set_language_standards(${target} ${language_standards_args})
    target_code_coverage(${target} AUTO ALL)
  endif()
endfunction()

function(swift_add_executable target)
  swift_add_target("${target}" executable ${ARGN})
endfunction()

function(swift_add_tool target)
  swift_add_target("${target}" tool ${ARGN})
endfunction()

function(swift_add_tool_library target)
  swift_add_target("${target}" tool_library ${ARGN})
endfunction()

function(swift_add_library target)
  swift_add_target("${target}" library ${ARGN})
endfunction()

function(swift_add_test_library target)
  swift_add_target("${target}" test_library ${ARGN})
endfunction()