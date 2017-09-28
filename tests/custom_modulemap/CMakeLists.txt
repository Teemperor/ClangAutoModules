cmake_minimum_required(VERSION 3.0)
project (custom-modulemap-test)

include_directories(inc)
set(ClangModules_CustomModulemapFolders ${CMAKE_CURRENT_SOURCE_DIR}/mods)
include(clang-modules/ClangModules.cmake)

add_executable(custom-modulemap-test main.cpp)
