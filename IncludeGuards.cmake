add_custom_target(fix-include-guards-${PROJECT_NAME}
  COMMAND
    ${CMAKE_CURRENT_LIST_DIR}/scripts/fix_include_guards.py `git ls-files '*.h'`
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
add_custom_target(fix-include-guards-check-${PROJECT_NAME}
  COMMAND git diff --exit-code
  DEPENDS fix-include-guards-${PROJECT_NAME}
  WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)

if(${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
  add_custom_target(
    fix-include-guards
    DEPENDS fix-include-guards-${PROJECT_NAME}
  )
  add_custom_target(
    fix-include-guards-check
    DEPENDS fix-include-guards-check-${PROJECT_NAME}
  )
endif()
