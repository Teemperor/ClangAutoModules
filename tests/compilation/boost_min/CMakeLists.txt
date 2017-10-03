cmake_minimum_required(VERSION 3.0)
project (boost-test)

add_compile_options(-std=c++11)

find_package(Boost 1.36.0)
if(Boost_FOUND)
  include_directories(${Boost_INCLUDE_DIRS})
endif()

include(clang-modules/ClangModules.cmake)

add_library(boost-test OBJECT main.cpp)
