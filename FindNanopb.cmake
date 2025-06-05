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
option(nanopb_BUILD_GENERATOR "" OFF)

if(USE_OFFICIAL_NANOPB)
  # Using official Nanopb from github and therefore manually including FindNanopb.cmake
  GenericFindDependency(
    TARGET protobuf-nanopb-static
    SOURCE_DIR "nanopb"
    SYSTEM_INCLUDES
  )

  # Instead of patches to the official Nanopb, we need to make all the adaptions here
  include("${nanopb_SOURCE_DIR}/extra/FindNanopb.cmake")
  target_include_directories(
    protobuf-nanopb-static
    PUBLIC
      $<BUILD_INTERFACE:${nanopb_SOURCE_DIR}>
  )
  # without this, the compilations fails due to C99 asserts
  target_compile_definitions(
    protobuf-nanopb-static
    PUBLIC
      PB_NO_STATIC_ASSERT
  )
  # This is needed to avoid warnings about switch statements on enum types
  target_compile_options(
    protobuf-nanopb-static
    PUBLIC
      -Wno-switch-enum
  )
  # This is how the lib is used
  add_library(protobuf-nanopb ALIAS protobuf-nanopb-static)
else()
  GenericFindDependency(
    TARGET protobuf-nanopb
    SOURCE_DIR "nanopb"
    SYSTEM_INCLUDES
  )
endif()
