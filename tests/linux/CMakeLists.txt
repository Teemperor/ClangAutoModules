cmake_minimum_required(VERSION 3.0)
project (linux-test)

add_compile_options(-std=c++11)

set(ClangModules_STD c++11)
include(clang-modules/ClangModules.cmake)

add_executable(sdl-test main.cpp)
