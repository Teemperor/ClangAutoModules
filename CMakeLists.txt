project(boost-compile)
cmake_minimum_required(VERSION 3.0)

option(use_modules "Build with C++ modules" On)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND use_modules)
  # using Clang
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmodules -fcxx-modules -Xclang -fdisable-module-hash -Xclang -fmodules-local-submodule-visibility -fmodules-cache-path=pcms -Rmodule-build")
  # no autopr warning
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")

  file(DOWNLOAD "https://github.com/Teemperor/ClangAutoModules/releases/download/0.2/ClangModules.cmake"
       "${CMAKE_BINARY_DIR}/ClangModules.cmake"
       EXPECTED_HASH SHA256=1a905f62fc9c31ea62f67e70f0e9f17442f9e3c36b4757adc4e3d71d9a39314e)
  set(ClangModules_CheckOnlyFor stl14 libc sys_types_only)
  include(${CMAKE_BINARY_DIR}/ClangModules.cmake)

elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  # TODO
  message(FATAL_ERROR "Can't build with gcc, we want to test clang")
endif()


set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

include_directories(inc)

add_library(boost-test OBJECT compile.cpp)
