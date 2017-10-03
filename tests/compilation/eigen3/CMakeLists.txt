cmake_minimum_required(VERSION 3.0)
project (eigen3-full)

add_compile_options(-std=c++11)

INCLUDE_DIRECTORIES(/usr/include/eigen3)
INCLUDE_DIRECTORIES(/usr/include/eigen)

set(ClangModules_DEBUG YES)
include(clang-modules/ClangModules.cmake)

add_library(eigen3-test OBJECT main.cpp)
