project(boost-compile)
cmake_minimum_required(VERSION 3.0)

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  # using Clang
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14 -fmodules -fcxx-modules -Xclang -fmodules-local-submodule-visibility -fmodules-cache-path=pcms -Rmodule-build")
  # no autopr warning
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")
elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  # TODO
endif()


set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

include_directories(inc)

add_library(boost-test OBJECT compile.cpp)
