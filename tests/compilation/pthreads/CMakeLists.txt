cmake_minimum_required(VERSION 3.0)
project (pthreads-test)

find_package(Threads)

include(clang-modules/ClangModules.cmake)

add_executable(pthreads-test main.cpp)
