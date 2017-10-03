cmake_minimum_required(VERSION 3.0)
project (linux)

include(clang-modules/ClangModules.cmake)

add_executable(sdl-test main.cpp)
