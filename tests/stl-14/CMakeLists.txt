cmake_minimum_required(VERSION 3.0)
project (stl14-full)

add_compile_options(-std=c++14)

include(clang-modules/ClangModules.cmake)

add_executable(stl-full main.cpp)
