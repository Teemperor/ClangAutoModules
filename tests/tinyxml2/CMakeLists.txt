cmake_minimum_required(VERSION 3.0)
project (tx2-full)

add_compile_options(-std=c++11)

include(clang-modules/ClangModules.cmake)

add_executable(tx2-test main.cpp)
TARGET_LINK_LIBRARIES(tx2-test tinyxml2)
