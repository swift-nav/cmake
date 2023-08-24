#
# Copyright (C) 2021 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

#
# A module to check header files for:
# - Include guards
# - Copyright notice
#
# When included will create 2 new targets:
# - fix-include-guards - Check all header files in the repository for the
#   above conditions
# - fix-include-guards-check - Depends on fix-include-guards then exits with
#   an error code if any changes were applied. Useful for enforcing checks
#   during CI runs
#
# Include guards are formatted according to the header file's location in the
# source tree. Copyright notices are boiler plate block comments
#
# Changes are applied in place
#

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
