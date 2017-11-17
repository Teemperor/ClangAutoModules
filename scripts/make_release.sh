#!/bin/bash
set -e

if [ "$#" -ne 1 ] ; then
  echo "Usage: $0 VERSION" >&2
  echo " E.g.: $0 0.2" >&2
  exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."

./scripts/gen.py

release="$1"
hashsum=`sha256sum ClangModules.cmake | cut -c 1-64`

echo "\`\`\`CMake"
echo "file(DOWNLOAD \"https://github.com/Teemperor/ClangAutoModules/releases/download/$release/ClangModules.cmake\""
echo "     \${CMAKE_BINARY_DIR}/ClangModules.cmake"
echo "     EXPECTED_HASH SHA256=$hashsum)"
echo "\`\`\`"
