cmake_minimum_required(VERSION 3.0)
project (console-output)

add_compile_options(-std=c++03)

include(ClangModules.cmake)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  file(WRITE "${CMAKE_BINARY_DIR}/HasClang" "")
endif()

add_executable(console-output main.cpp)
