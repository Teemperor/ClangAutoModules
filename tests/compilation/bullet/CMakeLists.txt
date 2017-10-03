cmake_minimum_required(VERSION 3.0)
project (bullet-test)

add_compile_options(-std=c++11)

find_package(Bullet REQUIRED Bullet)
include_directories(${BULLET_INCLUDE_DIRS})

set(ClangModules_DEBUG YES)
include(clang-modules/ClangModules.cmake)

add_executable(bullet-test main.cpp)
TARGET_LINK_LIBRARIES(bullet-test ${BULLET_LIBRARIES})
