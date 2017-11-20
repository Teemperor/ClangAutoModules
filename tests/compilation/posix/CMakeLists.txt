cmake_minimum_required(VERSION 3.0)
project (posix)

add_compile_options(-std=c++03)

set(ClangModules_DEBUG ON)
include(clang-modules/ClangModules.cmake)

add_executable(posix_test main.cpp)
