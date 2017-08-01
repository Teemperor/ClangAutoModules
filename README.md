# ClangModulesCMake

A simple CMake script for automatically setting up Clang's C++ modules for the third party libraries your project uses.

[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/Teemperor/ClangModulesCMake/blob/master/LICENSE.md)
[![Build Status](https://travis-ci.org/Teemperor/ClangModulesCMake.svg?branch=master)](https://travis-ci.org/Teemperor/ClangModulesCMake)

## Setup

1. Make a subtree of this repository in your project (or just download it).
2. At the point in your `CMakeLists.txt` where you have setup all your include paths, simply `include(/path/to/ClangModules.cmake)`. A simple SDL project that uses C++ modules for SDL/STL would look like this:

```CMake
cmake_minimum_required(VERSION 3.0)
project (my-SDL-application)

add_compile_options(-std=c++11)

INCLUDE(FindPkgConfig)
PKG_SEARCH_MODULE(SDL2 REQUIRED sdl2)
INCLUDE_DIRECTORIES(${SDL2_INCLUDE_DIRS} ${SDL2IMAGE_INCLUDE_DIRS})

##############
############## ClangModulesCMake
##############
include(clang-modules/ClangModules.cmake) # Only this line is needs to be added!
##############


add_executable(sdl-test main.cpp)
TARGET_LINK_LIBRARIES(sdl-test ${SDL2_LIBRARIES} ${SDL2IMAGE_LIBRARIES})

```

## Supported libraries

We currently have support for:

* STL for C++03, C++11, c++14
* SDL2
* Feel free to request more!

## How does it work?

After you've setup your include paths, ClangModulesCMake will go through your include paths and check there for headers that belongs to one of the supported libraries. When if finds a set of headers it supports, it will setup clang's virtual file system overlay and places a modulemap with this in the right place. Then it tries to compile the module and if this works, we add the module to the actual build configuration your project uses. If we can't compile this module for some reason, we won't add it to your build system to make sure we won't break anyone's builds.
