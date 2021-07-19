#!/bin/bash

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

failed=0
files=$(grep -l __attribute__ $(git ls-files $@))

if [[ -n "$files" ]];
then
  grep -Hn __attribute__ $files |
    while read line;
    do
      # Output a message similar to a compiler error so that editors/IDEs can parse it
      location=$(echo "$line" | cut -d: -f-2)
      code=$(echo "$line" | cut -d: -f3-)
      echo $(pwd)/$location: error: Do not use __attribute__, prefer one of the macros from swiftnav/macros.h
      echo "          $code"
    done
  failed=1
fi

exit $failed
