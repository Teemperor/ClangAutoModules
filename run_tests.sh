#!/bin/bash

function run_test {
  test_dir="$1"
  build_dir="$2"
  source_dir="$3"
  
  cd "$build_dir"
  test_name=`basename "$1"`
  echo "Running: $test_name"
  
  # Copy our test directory to the tmp directory
  rm -rf "$test_name"
  mkdir "$test_name"
  cd "$test_name"
  cp -r "$test_dir"/* .

  # Setup the clang-modules files in test_dir/clang-modules
  mkdir clang-modules
  cd clang-modules
  cp    "$source_dir"/ClangModules.cmake .
  cp -r "$source_dir"/files .
  
  # Build the project
  cd ..
  mkdir build
  cd build
  cmake ..
  make
  
  # Verify that we used the right modules
  
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for test_dir in $DIR/tests/*
do
  run_test "$test_dir" `pwd` "$DIR"
done
