cmake_minimum_required(VERSION 3.0)
project (libc)

add_compile_options(-std=c++03)

set(ClangModules_DEBUG ON)
include(clang-modules/ClangModules.cmake)

add_executable(libc main.cpp)
