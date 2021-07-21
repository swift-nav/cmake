include(CodeCoverage)
include(CompileOptions)
include(LanguageStandards)

cmake_policy(SET CMP0007 NEW)  # new behaviour list command no longer ignores empty elements

macro(swift_add_executable_collate_arguments prefix name)
  set(${name}_args "")
  foreach(arg IN LISTS ${name}_option ${name}_single ${name}_multi)
    if (${prefix}_${arg})
      list(APPEND ${name}_args ${prefix}_${arg} ${${prefix}_${arg}})
    endif()
  endforeach()
endmacro()

function(swift_add_executable target)
  set(this_option "")
  set(this_single "")
  set(this_multi "")

  set(compile_options_option WARNING NO_EXCEPTIONS EXCEPTIONS NO_RTTI RTTI)
  set(compile_options_single "")
  set(compile_options_multi ADD REMOVE)

  set(language_standards_option C_EXTENSIONS_ON)
  set(language_standards_single C CXX)
  set(language_standards_multi "")

  set(arg_option ${this_option} ${compile_options_option} ${language_standards_option})
  set(arg_single ${this_single} ${compile_options_single} ${language_standards_single})
  set(arg_multi ${this_multi} ${compile_options_multi} ${language_standards_multi})
  list(REMOVE_ITEM arg_option "")
  list(REMOVE_ITEM arg_single "")
  list(REMOVE_ITEM arg_multi "")

  cmake_parse_arguments(x "${arg_option}" "${arg_single}" "${arg_multi}" ${ARGN})

  swift_add_executable_collate_arguments(x compile_options)
  swift_add_executable_collate_arguments(x language_standards)

  add_executable(${target} ${x_UNPARSED_ARGUMENTS})
  swift_set_compile_options(${target} ${compile_options_args})
  swift_set_language_standards(${target} ${language_standards_args})
  target_code_coverage(${target} AUTO ALL)
endfunction()