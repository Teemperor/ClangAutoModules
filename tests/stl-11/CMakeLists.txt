cmake_minimum_required(VERSION 3.0)
project (stl-full)

add_compile_options(-std=c++11)

set(ClangModules_STD c++11)
include(clang-modules/ClangModules.cmake)

add_executable(stl-full main.cpp)
