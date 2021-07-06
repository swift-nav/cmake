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

if(NOT Bloaty_FOUND)

  find_program(Bloaty_EXECUTABLE bloaty)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Bloaty DEFAULT_MSG Bloaty_EXECUTABLE)

  set(Bloaty_FOUND ${Bloaty_FOUND} CACHE BOOL "Flag whether Bloaty package was found")
  mark_as_advanced(Bloaty_FOUND Bloaty_EXECUTABLE)

endif()
