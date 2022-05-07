#
# Copyright (C) 2022 Swift Navigation Inc.
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

option(sip_ENABLE_DOCS "" false)
option(sip_ENABLE_EXAMPLES "" false)
option(sip_ENABLE_TESTS "" false)
option(sip_ENABLE_TEST_LIBS "" false)

GenericFindDependency(
  TARGET sip
  SOURCE_DIR sip
  SYSTEM_INCLUDES
)
