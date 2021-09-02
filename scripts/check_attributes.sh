#!/bin/sh

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

result=0

files=$(git ls-files "$@")
while read -r file;
do
  matches=$(grep -Hn __attribute__ "$file")
  while read -r line;
  do
    if [ -n "$line" ];
    then
      location=$(echo "$line" | cut -d: -f-2)
      code=$(echo "$line" | cut -d: -f3-)
      echo "$(pwd)/$location: error: Do not use __attribute__, prefer one of the macros from swiftnav/macros.h"
      echo "          $code"
      result=1
    fi
  done <<EOF_MATCHES
  $matches
EOF_MATCHES
done <<EOF_FILES
$files
EOF_FILES

exit $result
