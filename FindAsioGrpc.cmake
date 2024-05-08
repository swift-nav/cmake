#
# Copyright (C) 2023 Swift Navigation Inc.
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

# asio-grpc has some logic to conditionally enable boost containers, this
# should just be default by default.
option(ASIO_GRPC_USE_BOOST_CONTAINER "(deprecated) Use Boost.Container instead of <memory_resource>" false)

GenericFindDependency(
  TARGET asio-grpc::asio-grpc-standalone-asio
  SOURCE_DIR asio-grpc
  SYSTEM_INCLUDES
)
