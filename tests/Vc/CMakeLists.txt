cmake_minimum_required(VERSION 3.0)
project (Vc-full)

add_compile_options(-std=c++11)

set(ClangModules_DEBUG On)
include(clang-modules/ClangModules.cmake)

add_library(Vc-test OBJECT main.cpp)
