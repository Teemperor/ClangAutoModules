cmake_minimum_required(VERSION 3.0)
project (geant4-test)

execute_process(
  COMMAND ${CMAKE_COMMAND} -E tar xf Geant4.zip
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

include_directories(Geant4)
include_directories(Geant4/CLHEP)

add_compile_options(-std=c++11)

include(clang-modules/ClangModules.cmake)
add_library(geant4-test STATIC main.cpp)
