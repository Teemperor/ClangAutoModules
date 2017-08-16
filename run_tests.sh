#!/bin/bash
set -e

export CC="$1"
export CXX="$2"
shift
shift

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
rm -rf build
mkdir build
cd build
cmake ..
ctest --output-on-failure $@
