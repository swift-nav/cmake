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
# should just be defaulted to false since the standard library offers the same
# functionality.
option(ASIO_GRPC_USE_BOOST_CONTAINER "(deprecated) Use Boost.Container instead of <memory_resource>" false)

GenericFindDependency(
  TARGET asio-grpc::asio-grpc-standalone-asio
  SOURCE_DIR asio-grpc
  SYSTEM_INCLUDES
)

# Older libc++ versions like the one that ships with clang < v16 doesn't offer
# the "memory_resource" standard header which is used by the library, instead
# we conditionally select it to use "experimental/memory_resource" which is
# available. The conditional selection is done via a customer preprocessor
# which we've (Swift Navigation) introduced.
include(CheckExperimentalMemoryResource)
check_experimental_memory_resource(IS_EXPERIMENTAL_MEMORY_RESOURCE)
if (IS_EXPERIMENTAL_MEMORY_RESOURCE)
  target_compile_definitions(asio-grpc-standalone-asio
    INTERFACE
      SWIFTNAV_EXPERIMENTAL_MEMORY_RESOURCE
  )
endif()

# asio-grpc uses language features that are removed in c++20, the libc++
# implementation actually removed these features unless you set a special
# macro.
include(CheckLibcpp)
check_libcpp(IS_LIBCPP)
if (IS_LIBCPP)
  target_compile_definitions(asio-grpc-standalone-asio
    INTERFACE
      _LIBCPP_ENABLE_CXX20_REMOVED_FEATURES
  )
endif()
