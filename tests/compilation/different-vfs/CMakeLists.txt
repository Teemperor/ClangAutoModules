cmake_minimum_required(VERSION 3.0)
project (different-vfs)

add_compile_options(-std=c++03)

set(ClangModules_OutputVFSFile "${CMAKE_SOURCE_DIR}/UniqueFileName")
include(clang-modules/ClangModules.cmake)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  if(NOT EXISTS "${CMAKE_SOURCE_DIR}/UniqueFileName")
    message(FATAL_ERROR "Couldn't find our specified VFS file!")
  endif()
endif()

add_executable(different-vfs main.cpp)
