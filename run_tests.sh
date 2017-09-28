#!/bin/bash
set -e

export CC="$1"
export CXX="$2"
shift
shift

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "Checking for PEP-8"
if ! [ -x "$(command -v flake8)" ]; then
  pip install --user flake8
fi
echo "Running flake8..."
if [ ! -f ClangModules.py ]; then
    echo "ClangModules.py not found!"
    exit 1
fi
flake8 ClangModules.py

rm -rf build
mkdir build
cd build
cmake ..
ctest --output-on-failure $@

