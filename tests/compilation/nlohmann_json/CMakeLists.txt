cmake_minimum_required(VERSION 3.0)
project (nlohmann-test)

add_compile_options(-std=c++11)

include_directories(.)
include(clang-modules/ClangModules.cmake)
add_executable(nlohmann-test main.cpp)
TARGET_LINK_LIBRARIES(nlohmann-test glog)
