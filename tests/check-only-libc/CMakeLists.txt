cmake_minimum_required(VERSION 3.0)
project (check-only)

add_compile_options(-std=c++11)

set(ClangModules_CheckOnlyFor libc)
include(clang-modules/ClangModules.cmake)

add_executable(check-only main.cpp)
