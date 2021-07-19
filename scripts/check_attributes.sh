#!/bin/bash

failed=0
files=$(grep -l __attribute__ $(git ls-files '*.[ch]') $(git ls-files '*.[ch]pp') $(git ls-files '*.cc'))

if [[ -n "$files" ]];
then
  grep -n __attribute__ $files |
    while read line;
    do
      echo $(pwd)/$line
    done
  failed=1
fi

exit $failed
