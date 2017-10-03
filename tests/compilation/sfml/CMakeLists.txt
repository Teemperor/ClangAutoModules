cmake_minimum_required(VERSION 3.0)
project (sfml-test)

add_compile_options(-std=c++11)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/modules" ${CMAKE_MODULE_PATH})
find_package(SFML 2 REQUIRED system window graphics audio)
include_directories(${SFML_INCLUDE_DIRS})

include(clang-modules/ClangModules.cmake)

add_executable(sfml-test main.cpp)
TARGET_LINK_LIBRARIES(sfml-test ${SFML_LIBRARIES})
