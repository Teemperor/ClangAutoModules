#!/bin/bash

declare -a errors

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
  
  while read p; do
    # Verify that we used the right modules
    find ./pcms/ -name "$p-*\\.pcm" | grep -q .

    if [ $? -ne 0 ]; then
      errors+=("$test_name -> can't find $p")
      echo "ERROR: $test_name -> can't find PCM for $p"
    else
      echo "Found PCM for $p: $(find . -name "$p-*\\.pcm")"
    fi
  done < ../NEEDS_PCMS
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for test_dir in $DIR/tests/*
do
  run_test "$test_dir" `pwd` "$DIR"
done
