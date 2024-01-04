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

if(TARGET asio::asio)
  return()
endif()

add_library(asio_asio INTERFACE)
add_library(asio::asio ALIAS asio_asio)

target_include_directories(asio_asio
  SYSTEM INTERFACE
    ${PROJECT_SOURCE_DIR}/third_party/asio/asio/include
)
