#!/bin/bash

echo "INFO: Generating a modulemap and module_error file in the current directory."
echo "INFO: Pass a clang binary to this script to test a custom clang version."

if [ $# -ne 1 ]; then
  echo "INFO: No clang specified, using default one (clang++)"
  clang_cc=clang
else
  echo "INFO: Using clang $1"
  clang_cc="$1"
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "" > module_error

find . -name "*.hpp" | sed "s/\.\///g" | cut -c 5- | while read line
do
  sed "s#HEADER#$line#g" "$DIR/header-test.cpp" > /tmp/tmp.cpp

  echo "#####################################################" >> module_error
  echo "HEADER: $line" >> module_error
  echo "#####################################################" >> module_error

  $clang_cc -Werror -I "$DIR/inc" -std=c++14 /tmp/tmp.cpp 2>> module_error
  if [ $? -ne 0 ]; then
    (>&2 echo "FAIL: $line")
    continue
  fi
  (>&2 echo "PASS: $line")
  echo "$line"
done > modulemap
