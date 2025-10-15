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

include("GenericFindDependency")
option(CHECK_ENABLE_TESTS "" OFF)
option(CHECK_INSTALL "" OFF)

# Store current compile options to restore later
set(_SAVED_CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

# Temporarily modify CMAKE_C_FLAGS to disable implicit-function-declaration errors
# for the check library compilation (needed for Windows/MinGW compatibility)
if(WIN32)
  string(REPLACE "-Werror" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-error=implicit-function-declaration")
endif()

GenericFindDependency(
  TARGET check
  SYSTEM_INCLUDES
)

# Restore original compile flags
set(CMAKE_C_FLAGS "${_SAVED_CMAKE_C_FLAGS}")
unset(_SAVED_CMAKE_C_FLAGS)
