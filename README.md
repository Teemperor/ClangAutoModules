# ClangAutoModules

Automatically brings clang modules to your system libraries in your CMake project.

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/Teemperor/ClangModulesCMake/blob/master/LICENSE.md)
[![Build Status](https://travis-ci.org/Teemperor/ClangAutoModules.svg?branch=master)](https://travis-ci.org/Teemperor/ClangAutoModules)

## Setup

There are three different ways to use ClangAutoModules:

1. Embed the standalone script it in your CMake project

```CMake

```

2. Use is externally to compile a CMake project:

```bash
CC=path/to/clang_modules CXX=path/to/clang_modules++ cmake ...
```

3. Use the python backend directly in your own custom build system.

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
