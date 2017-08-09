cmake_minimum_required(VERSION 3.0)
project (glog-test)

add_compile_options(-std=c++11)

include(clang-modules/ClangModules.cmake)

add_executable(glog-test main.cpp)
TARGET_LINK_LIBRARIES(glog-test glog)
