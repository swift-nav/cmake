if(SWIFT_CLANG_TIDY_INCLUDED)
  return()
endif()
set(SWIFT_CLANG_TIDY_INCLUDED TRUE)

option(REPORT_UNLINTED_TARGETS "" OFF)

include(ListTargets)

# This is required so that clang-tidy can work out what compiler options to use
# for each file
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "Export compile commands" FORCE)

function(swift_tidy_target target)
  if(${target} IN_LIST SWIFT_TIDY_TARGETS)
    return()
  endif()
  set(targets_to_tidy ${SWIFT_TIDY_TARGETS} ${target})
  set(SWIFT_TIDY_TARGETS "${targets_to_tidy}" CACHE STRING "" FORCE)
endfunction()

function(swift_create_tidy_targets)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Only create targets from top level project
    return()
  endif()

  # Currently only use clang-tidy-6.0
  find_program(CLANG_TIDY NAMES clang-tidy-6.0)

  if("${CLANG_TIDY}" STREQUAL "CLANG_TIDY-NOTFOUND")
    message(WARNING "Could not find clang-tidy-6.0, lint targets will not be created")
    return()
  endif()

  swift_list_targets(lintable_targets_in_this_repository EXCLUDE_THIRD_PARTY TYPE "EXECUTABLE" "DYNAMIC_LIBRARY" "STATIC_LIBRARY" "OBJECT_LIBRARY")
  message("lintable_targets_in_this_repository ${lintable_targets_in_this_repository}")

  set(enabled_categories
    # bugprone could probably do with being turned on
    # bugprone*
    cert*
    clang-analyzer*
    cppcoreguidelines*
    google*
    misc*
    modernize*
    performance*
    readability*
    )

  set(disabled_checks
    # Don't need OSX checks
    -clang-analyzer-osx*
    -clang-analyzer-optin.osx.*

    # Test suites aren't linted
    -clang-analyzer-apiModeling.google.GTest

    # Don't care about LLVM conventions
    -clang-analyzer-llvm.Conventions

    # Function size is not enforced through clang-tidy, sonar cloud has its own check
    -readability-function-size

    # No using MPI
    -clang-analyzer-optin.mpi*

    # No ObjC code anywhere
    -google-objc*

    # clang-format takes care of indentation
    -readability-misleading-indentation

    # Doesn't appear to be functional, even if it were appropriate
    -readability-identifier-naming

    # Caught by compiler, -Wunused-parameter
    -misc-unused-parameters

    # Duplicate of cppcoreguidelines-pro-type-cstyle-cast
    -google-readability-casting

    # We have a external function blacklist which is much faster, don't need clang to do it
    -clang-analyzer-security.insecureAPI*

    # All the following checks were disabled when the CI project started. They are 
    # left like this to avoid having to make too many code changes. This should not
    # be taken as an endorsement of anything.
    -cert-dcl03-c
    -cert-dcl21-cpp
    -cert-err34-c
    -cert-err58-cpp
    -clang-analyzer-alpha*
    -clang-analyzer-core.CallAndMessage
    -clang-analyzer-core.UndefinedBinaryOperatorResult
    -clang-analyzer-core.uninitialized.Assign
    -clang-analyzer-core.uninitialized.UndefReturn
    -clang-analyzer-optin.cplusplus.VirtualCall
    -clang-analyzer-optin.performance.Padding
    -cppcoreguidelines-owning-memory
    -cppcoreguidelines-pro-bounds-array-to-pointer-decay
    -cppcoreguidelines-pro-bounds-constant-array-index
    -cppcoreguidelines-pro-bounds-pointer-arithmetic
    -cppcoreguidelines-pro-type-member-init
    -cppcoreguidelines-pro-type-static-cast-downcast
    -cppcoreguidelines-pro-type-union-access
    -cppcoreguidelines-pro-type-vararg
    -cppcoreguidelines-special-member-functions
    -google-runtime-references
    -misc-static-assert
    -modernize-deprecated-headers
    -modernize-pass-by-value
    -modernize-redundant-void-arg
    -modernize-return-braced-init-list
    -modernize-use-auto
    -modernize-use-bool-literals
    -modernize-use-default-member-init
    -modernize-use-emplace
    -modernize-use-equals-default
    -modernize-use-equals-delete
    -modernize-use-using
    -performance-unnecessary-value-param
    -readability-avoid-const-params-in-decls
    -readability-non-const-parameter
    -readability-redundant-declaration
    -readability-redundant-member-init
    )

  set(all_checks
    -*
    ${enabled_categories}
    ${disabled_checks}
    )

  string(REPLACE ";" "," comma_checks "${all_checks}")
  file(WRITE  ${CMAKE_SOURCE_DIR}/.clang-tidy "# Automatically generated, do not edit\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "# Enabled checks are generated from SwiftClangTidy.cmake\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "Checks: \"${comma_checks}\"\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "HeaderFilterRegex: '.*'\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "AnalyzeTemporaryDtors: true\n")

  unset(all_abs_srcs)
  unset(world_abs_srcs)

  foreach(target IN LISTS SWIFT_TIDY_TARGETS)
    message("Tidy ${target}")

    get_target_property(target_srcs ${target} SOURCES)
    get_target_property(target_dir ${target} SOURCE_DIR)
    unset(abs_srcs)
    foreach(file ${target_srcs})
      get_filename_component(abs_file ${file} ABSOLUTE BASE_DIR ${target_dir})
      list(APPEND abs_srcs ${abs_file})
    endforeach()
    list(APPEND world_abs_srcs ${abs_srcs})
    if(${target} IN_LIST lintable_targets_in_this_repository)
      list(APPEND all_abs_srcs ${abs_srcs})
      list(REMOVE_ITEM lintable_targets_in_this_repository ${target})
    endif()

    #message("Linting ${target}")
    add_custom_target(clang-tidy-${target} 
      COMMAND 
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary ${CLANG_TIDY} -p ${CMAKE_BINARY_DIR} -export-fixes=${CMAKE_SOURCE_DIR}/fixes-${target}.yaml ${abs_srcs}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      )
    add_custom_target(clang-tidy-${target}-check
      COMMAND test ! -f ${CMAKE_SOURCE_DIR}/fixes-${target}.yaml
      DEPENDS clang-tidy-${target}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
  endforeach()

  if(NOT all_abs_srcs)
    message(WARNING "No sources to lint, that doesn't sound right")
  else()
    list(REMOVE_DUPLICATES all_abs_srcs)

    add_custom_target(clang-tidy-all
      COMMAND
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary ${CLANG_TIDY} -p ${CMAKE_BINARY_DIR} -export-fixes ${CMAKE_SOURCE_DIR}/fixes.yaml ${all_abs_srcs}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      )
    add_custom_target(clang-tidy-all-check
      COMMAND test ! -f ${CMAKE_SOURCE_DIR}/fixes.yaml
      DEPENDS clang-tidy-all
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
  endif()

  if(NOT world_abs_srcs)
    messages(WARNING "No world sources to lint, that doesn't sound right")
  else()
    list(REMOVE_DUPLICATES world_abs_srcs)

    add_custom_target(clang-tidy-world
      COMMAND
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary ${CLANG_TIDY} -p ${CMAKE_BINARY_DIR} -export-fixes ${CMAKE_SOURCE_DIR}/fixes.yaml ${world_abs_srcs}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      )
    add_custom_target(clang-tidy-world-check
      COMMAND test ! -f ${CMAKE_SOURCE_DIR}/fixes.yaml
      DEPENDS clang-tidy-world
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
  endif()

  if(lintable_targets_in_this_repository AND REPORT_UNLINTED_TARGETS)
    message(WARNING "The following targets defined in this repository will not be linted: ${lintable_targets_in_this_repository}")
  endif()
endfunction()

