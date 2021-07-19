#!/bin/bash

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
