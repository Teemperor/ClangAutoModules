#!/bin/bash

export CC=$1
export CXX=$2

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
cd ..
mkdir build
cd build
cmake ..
make
