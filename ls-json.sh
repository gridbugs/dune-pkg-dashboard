#!/bin/sh

echo "["
first="1"
ls -1 $1 | while read f; do
  if [ $first = "1" ]; then
    first="0"
    printf "  \"$f\""
  else
    printf ",\n  \"$f\""
  fi
done
echo
echo "]"
