#!/bin/bash

export CC="$1"
export CXX="$2"

skip_checks="NO"
if [ "$3" == "SKIP_CHECKS" ]; then
  echo "Disabling PCM checks. Only testing compilation..."
  skip_checks="YES"
fi

function run_test {
  set -e
  test_dir="$1"
  build_dir="$2"

  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  cd "$build_dir"
  test_name=`basename "$1"`
  echo "- Running test: $test_name"
  
  # Copy our test directory to the tmp directory
  rm -rf "$test_name"
  mkdir "$test_name"
  cd "$test_name"
  cp -r "$test_dir"/* .

  # Setup the clang-modules files in test_dir/clang-modules
  mkdir clang-modules
  cd clang-modules
  $DIR/gen.py

  # Build the project
  cd ..
  mkdir build
  cd build
  FLAGS="-H"
  if [[ $CXX == *"clang"* ]]; then
    FLAGS="$FLAGS -Rmodule-build"
  fi
  CXX_FLAGS="-H"
  if [[ $CXX == *"clang"* ]]; then
    CXX_FLAGS="$CXX_FLAGS -Rmodule-build"
  fi

  set +e
  cmake -DCMAKE_C_FLAGS="$FLAGS"  -DCMAKE_CXX_FLAGS="$CXX_FLAGS" ..
  if [ $? -ne 0 ]; then
    echo "CMake failed!"
  fi
  make VERBOSE=1
  if [ $? -ne 0 ]; then
    echo "make failed!"
  fi
  
  if [ "$skip_checks" == "NO" ] ; then
    while read p; do
      # Verify that we used the right modules
      find ./pcms/ -name "$p-*\\.pcm" | grep -q .

      if [ $? -ne 0 ]; then
        echo "ERROR: can't find PCM for $p"
        echo "PWD: $(pwd)"
        cd ..
        echo "TREE:"
        tree
        cd build
        echo "YAML:"
        cat ClangModules_*.yaml
        echo "CMakeFiles/CMakeError.log"
        cat CMakeFiles/CMakeError.log
        echo "CMakeFiles/CMakeOutput.log"
        cat CMakeFiles/CMakeOutput.log
        exit 1
      else
        echo "-- Found PCM for $p: $(find . -name "$p-*\\.pcm")"
      fi
    done < ../NEEDS_PCMS
  fi
}

run_test "$4" `pwd`

