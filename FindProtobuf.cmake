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

option(ABSL_PROPAGATE_CXX_STD "Use CMake C++ standard meta features (e.g. cxx_std_14) that propagate to targets that link to Abseil" true)
option(protobuf_INSTALL "Install protobuf binaries and files" OFF)
option(utf8_range_ENABLE_INSTALL "Configure installation" OFF)

include("GenericFindDependency")
option(protocol_BUILD_TESTS "" OFF)
GenericFindDependency(
  TARGET "libprotobuf"
  SOURCE_DIR "protobuf"
  SYSTEM_INCLUDES
)
