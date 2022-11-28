#
# Copyright (C) 2022 Swift Navigation Inc.
# Contact: Swift Navigation <dev@swift-nav.com>
#
# This source is subject to the license found in the file 'LICENSE' which must
# be be distributed together with this source. All other rights reserved.
#
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#

# Writes project metadata to a json file at the build root.
function(write_metadata)
  if(NOT ${PROJECT_NAME} STREQUAL ${CMAKE_PROJECT_NAME})
    return()
  endif()

  # TODO: Make sure this executes successfully
  execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE SHA
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  set(project_data "\"project\": \"${CMAKE_PROJECT_NAME}\"")
  set(sha_data "\"sha\": \"${SHA}\"")
  set(compiler_data "\"compiler\": \"${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION}\"")

  set(payload "{ ${project_data}, ${sha_data}, ${compiler_data} }")

  file(WRITE ${CMAKE_BINARY_DIR}/project.json ${payload})

endfunction()
