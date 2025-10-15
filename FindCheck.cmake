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
GenericFindDependency(
  TARGET check
  SYSTEM_INCLUDES
)

# Disable warnings-as-errors for check library since it's a third-party dependency
# and its source files are compiled directly (not just headers), so SYSTEM_INCLUDES
# doesn't suppress warnings. This prevents issues like implicit function declarations
# on Windows (e.g., alarm() in timer_delete.c) from breaking the build.
if(TARGET check)
  target_compile_options(check PRIVATE $<$<COMPILE_LANGUAGE:C>:-Wno-error>)
endif()
if(TARGET checkShared)
  target_compile_options(checkShared PRIVATE $<$<COMPILE_LANGUAGE:C>:-Wno-error>)
endif()
