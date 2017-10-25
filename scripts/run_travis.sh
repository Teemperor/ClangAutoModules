#!/bin/bash

rm -rf build

export CC=$1
export CXX=$2

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
cd ..
mkdir build
cd build
cmake -Duse_modules=$3 ..
if [[ "$3" == "On" ]]; then
  echo "Building with modules on"
  set +e
  make
  set -e
  find . -name "boost_*.pcm" | xargs -L1 basename | rev | cut -c 5- | rev > found_pcms
  echo "Found PCMS:"
  cat found_pcms
  python "$DIR/check_pcms.py" "$DIR/../working_pcms" found_pcms
  python "$DIR/size_check_pcms.py"
else
  echo "Building with modules off"
  make
fi
