cmake_minimum_required(VERSION 3.0)
project (required-mods)

add_compile_options(-std=c++11)

set(ClangModules_RequiredModules stl14)
include(clang-modules/ClangModules.cmake)

add_executable(required-mods main.cpp)
