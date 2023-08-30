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

option(starling_ENABLE_TESTS "" true)
option(starling_ENABLE_TEST_LIBS "" true)
option(starling_ENABLE_EXAMPLES "" true)

GenericFindDependency(
  TARGET pvt-engine
  ADDITIONAL_TARGETS
    math_routines
    sensorfusion
    pvt_driver
    pvt-common
    pvt-engine
    pvt-sbp-logging
    pvt-sizes
    pvt-version
    starling-build-config
    starling-util
  SOURCE_DIR starling
)
