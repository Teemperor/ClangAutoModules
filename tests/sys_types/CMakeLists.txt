cmake_minimum_required(VERSION 3.0)
project (sys_types)

add_compile_options(-std=c++03)

set(ClangModules_DEBUG ON)
include(clang-modules/ClangModules.cmake)

add_executable(sys_types main.cpp)
