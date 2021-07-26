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
option(BENCHMARK_ENABLE_TESTING "" OFF)
option(BENCHMARK_ENABLE_INSTALL "" OFF)
option(BENCHMARK_ENABLE_GTEST_TESTS "" OFF)
option(BENCHMARK_ENABLE_EXCEPTIONS "" OFF)
GenericFindDependency(
  TARGET benchmark
  SYSTEM_INCLUDES
)

# We've found that other packages expect to have the LIBRT variable
# not set, so having it cached can cause issues
unset(LIBRT)
unset(LIBRT CACHE)
