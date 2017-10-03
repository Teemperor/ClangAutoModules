cmake_minimum_required(VERSION 3.0)
project (stl03-full)

add_compile_options(-std=c++03)

file(RENAME clang-modules AnotherDirectoryName)

if(EXISTS clang-modules)
  message(ERROR "Couldn't move directory?")
endif()

include(AnotherDirectoryName/ClangModules.cmake)

add_executable(stl-full main.cpp)
