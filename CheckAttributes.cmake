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

function(create_check_attributes_target)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    # Only create for top level projects
    return()
  endif()

  set(argOption "")
  set(argSingle "")
  set(argMulti "EXCLUDE")

  cmake_parse_arguments(x "${argOption}" "${argSingle}" "${argMulti}" ${ARGN})

  set(arguments "'*.[ch]'" "'*.[ch]pp'" "'*.cc'" "'*.[ch]xx'")
  foreach(excl ${x_EXCLUDE})
    list(APPEND arguments ":!:${excl}")
  endforeach()

  add_custom_target(check-attributes ALL
    ${CMAKE_CURRENT_LIST_DIR}/cmake/common/scripts/check_attributes.sh ${arguments}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )

endfunction()
