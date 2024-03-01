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

option(SWIFT_ENABLE_SCCACHE "Use sccache to speed up compilation process" OFF)

if(SWIFT_ENABLE_SCCACHE)
  find_program(SCCACHE_PATH sccache)
  SCCACHE_IGNORE_SERVER_IO_ERROR=1
  if(SCCACHE_PATH)
    message(STATUS "Using sccache at ${SCCACHE_PATH}")
    set(CMAKE_C_COMPILER_LAUNCHER ${SCCACHE_PATH})
    set(CMAKE_CXX_COMPILER_LAUNCHER ${SCCACHE_PATH})
  else()
    message(STATUS "Could not find sccache")
  endif()
endif()
