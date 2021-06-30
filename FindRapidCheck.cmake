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

cmake_minimum_required(VERSION 3.2)
include("GenericFindDependency")

set(RC_ENABLE_GTEST ON CACHE BOOL "" FORCE)

GenericFindDependency(
  TARGET rapidcheck
  ADDITIONAL_TARGETS
    rapidcheck_gtest
  SYSTEM_INCLUDES
)

