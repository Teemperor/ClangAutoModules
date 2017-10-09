cmake_minimum_required(VERSION 3.0)
project (needed-flags-test)

add_compile_options(-std=c++11)

set(ClangModules_WithoutClang ON)
include(ClangModules.cmake)

add_executable(needed-flags-test main.cpp)
TARGET_LINK_LIBRARIES(needed-flags-test glog)
