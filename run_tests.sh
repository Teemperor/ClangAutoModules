#!/bin/bash

skip_checks="NO"
export CC="$1"
export CXX="$2"

if [ "$3" == "NO" ]; then
  echo "Disabling PCM checks. Only testing for compilation..."
  skip_checks="YES"
fi

declare -a errors

function run_test {
  set -e
  test_dir="$1"
  build_dir="$2"
  source_dir="$3"
  
  cd "$build_dir"
  test_name=`basename "$1"`
  echo "Running test: $test_name"
  
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
  make VERBOSE=1
  set +e
  
  if [ "$skip_checks" == "NO" ] ; then
    while read p; do
      # Verify that we used the right modules
      find ./pcms/ -name "$p-*\\.pcm" | grep -q .

      if [ $? -ne 0 ]; then
        errors+=("$test_name -> can't find $p")
        echo "ERROR: $test_name -> can't find PCM for $p"
        echo "PWD: $(pwd)"
        cd ..
        echo "TREE:"
        tree
        cd build
      else
        echo "Found PCM for $p: $(find . -name "$p-*\\.pcm")"
      fi
    done < ../NEEDS_PCMS
  fi
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for test_dir in $DIR/tests/*
do
  run_test "$test_dir" `pwd` "$DIR"
done

if [ ${#errors[@]} -eq 0 ]; then
    echo "No errors. All tests passed."
else
    echo "Tests failed:"
    printf '%s\n' "${errors[@]}"
    exit 1
fi
