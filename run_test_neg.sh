#!/bin/bash

if [ "$4" == "SKIP_CHECKS" ]; then
  echo "Disabling PCM checks. Skipping check"
  exit 0
fi

output=$(bash -x "$1" "$2" "$3" "$4" "$5" 2>&1)
ret_code=$?

set -e

if [ "$ret_code" -eq "0" ]; then
  echo "Error: Test $4 succeeded but was expected to fail"
fi

err=$(cat "$5/EXPECTED_ERROR" | sed -e 's/[[:space:]]*$//')
echo "$output" | grep -q "$err"

set +e

if [ $? -eq 0 ]; then
    echo "Found expected error \"$err\" in \"$output\""
else
    echo "Error: Could not find expected error \"$err\" in \"$output\""
    exit 1
fi
