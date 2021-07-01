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

option(SWIFT_ENABLE_CCACHE "Use ccache to speed up compilation process" OFF)

if(SWIFT_ENABLE_CCACHE)
  find_program(CCACHE_PATH ccache)
  if(CCACHE_PATH)
    message(STATUS "Using ccache at ${CCACHE_PATH}")
    set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ${CCACHE_PATH})
    set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ${CCACHE_PATH})
  else()
    message(STATUS "Could not find ccache")
  endif()
endif()
