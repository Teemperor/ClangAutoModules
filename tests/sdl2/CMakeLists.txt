cmake_minimum_required(VERSION 3.0)
project (stl-full)

add_compile_options(-std=c++11)

INCLUDE(FindPkgConfig)
PKG_SEARCH_MODULE(SDL2 REQUIRED sdl2)
INCLUDE_DIRECTORIES(${SDL2_INCLUDE_DIRS} ${SDL2IMAGE_INCLUDE_DIRS})

set(ClangModules_STD c++11)
include(clang-modules/ClangModules.cmake)

add_executable(sdl-test main.cpp)
TARGET_LINK_LIBRARIES(sdl-test ${SDL2_LIBRARIES} ${SDL2IMAGE_LIBRARIES})
