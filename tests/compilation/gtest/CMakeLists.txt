cmake_minimum_required(VERSION 3.0)
project (gtest-test)

add_compile_options(-std=c++11)

find_package(GTest)
include_directories(${GTEST_INCLUDE_DIRS})

include(clang-modules/ClangModules.cmake)

# Don't try to link against gtest as this is messed up on ubuntu (which we use on travis)
add_library(gtest-test OBJECT main.cpp)
