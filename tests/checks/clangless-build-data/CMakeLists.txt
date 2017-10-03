cmake_minimum_required(VERSION 3.0)
project (clangless-test)

add_compile_options(-std=c++11)

set(ClangModules_WithoutClang ON)
include(ClangModules.cmake)

add_executable(clangless-test main.cpp)
TARGET_LINK_LIBRARIES(clangless-test glog)

if ("${CMAKE_CXX_FLAGS}" MATCHES "-fmodules")
  message(FATAL_ERROR "Shouldn't have set -fmodules in clangless mode!")
endif()
