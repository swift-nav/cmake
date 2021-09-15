if(SWIFT_CLANG_TIDY_INCLUDED)
  return()
endif()
set(SWIFT_CLANG_TIDY_INCLUDED TRUE)

include(ListTargets)

function(swift_tidy_target target)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()
  if(${target} IN_LIST SWIFT_TIDY_TARGETS)
    return()
  endif()
  set(targets_to_tidy ${SWIFT_TIDY_TARGETS} ${target})
  set(SWIFT_TIDY_TARGETS "${targets_to_tidy}" CACHE STRING "" FORCE)
endfunction()

function(swift_create_tidy_targets)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  swift_list_targets(lintable_targets EXCLUDE_THIRD_PARTY TYPE "EXECUTABLE" "DYNAMIC_LIBRARY" "STATIC_LIBRARY" "OBJECT_LIBRARY")

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
  file(WRITE ${CMAKE_SOURCE_DIR}/.clang-tidy "# Automatically generated, do not edit\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "Checks: \"${comma_checks}\"\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "HeaderFilterRegex: '.*'\n")
  file(APPEND ${CMAKE_SOURCE_DIR}/.clang-tidy "AnalyzeTemporaryDtors: true\n")

  unset(all_abs_srcs)

  foreach(target IN LISTS SWIFT_TIDY_TARGETS)
    message("Tidy ${target}")
    list(REMOVE_ITEM lintable_targets ${target})

    get_target_property(target_srcs ${target} SOURCES)
    get_target_property(target_dir ${target} SOURCE_DIR)
    unset(abs_srcs)
    foreach(file ${target_srcs})
      get_filename_component(abs_file ${file} ABSOLUTE BASE_DIR ${target_dir})
      list(APPEND abs_srcs ${abs_file})
    endforeach()
    list(APPEND all_abs_srcs ${abs_srcs})

    message("Linting ${target}")
    add_custom_target(clang-tidy-${target} 
      COMMAND 
      ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary /usr/bin/clang-tidy-6.0 -p ${CMAKE_BINARY_DIR} -export-fixes=${CMAKE_SOURCE_DIR}/fixes-${target}.yaml ${abs_srcs}
      WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
      )
  endforeach()

  list(REMOVE_DUPLICATES all_abs_srcs)

  add_custom_target(clang-tidy-all
    COMMAND
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/scripts/run-clang-tidy.py -clang-tidy-binary /usr/bin/clang-tidy-6.0 -p ${CMAKE_BINARY_DIR} -export-fixes ${CMAKE_SOURCE_DIR}/fixes.yaml ${all_abs_srcs}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )

  if(lintable_targets)
    message(WARNING "The following targets will not be linted: ${lintable_targets}")
  endif()
endfunction()
