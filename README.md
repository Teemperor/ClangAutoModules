# ClangAutoModules

Automatically brings clang modules to your system libraries in your CMake project.

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/Teemperor/ClangModulesCMake/blob/master/LICENSE.md)
[![Build Status](https://travis-ci.org/Teemperor/ClangAutoModules.svg?branch=master)](https://travis-ci.org/Teemperor/ClangAutoModules)

## Setup

There are two different ways to use ClangAutoModules:

1. Embed the standalone script it in your CMake project:

```CMake
file(DOWNLOAD "https://github.com/Teemperor/ClangAutoModules/releases/download/0.2/ClangModules.cmake"
     "${CMAKE_BINARY_DIR}/ClangModules.cmake"
     EXPECTED_HASH SHA256=1a905f62fc9c31ea62f67e70f0e9f17442f9e3c36b4757adc4e3d71d9a39314e)

include(${CMAKE_BINARY_DIR}/ClangModules.cmake)
```

[More information](docs/CMakeScript.md)

2. Use is to externally configure a CMake project:

```bash
CC=path/to/clang_modules CXX=path/to/clang_modules++ cmake ...
```

[More information](docs/ExternalConfig.md)

## Supported libraries

We currently have support for:

* STL for C++03, C++11, c++14
* SDL2
* boost (minimal, WIP)
* eigen3
* libc
* SFML
* glog
* gtest
* bullet
* linux headers (minimal, WIP)
* tinyxml
* tinyxml2
* [Feel free to request more!](https://github.com/Teemperor/ClangModulesCMake/issues/new)
