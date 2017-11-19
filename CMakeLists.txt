project(boost-compile)
cmake_minimum_required(VERSION 3.0)

option(use_modules "Build with C++ modules" On)

if(use_modules MATCHES print)
  set(textual_check On)
  set(use_modules On)
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND use_modules)
  # using Clang
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmodules -fcxx-modules -Xclang -fdisable-module-hash -Xclang -fmodules-local-submodule-visibility -fmodules-cache-path=pcms")
  # no autopr warning
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")
  # embed all headers to stress size limit
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -fmodules-embed-all-files")

  if (textual_check)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -H -Wno-everything")
  endif()

  file(DOWNLOAD "https://github.com/Teemperor/ClangAutoModules/releases/download/0.2.1/ClangModules.cmake"
       ${CMAKE_BINARY_DIR}/ClangModules.cmake
       EXPECTED_HASH SHA256=66ca91179df6806f3b7a7e25667d819252b026263aa5f69b868e3588c95c16a8)
  set(ClangModules_CheckOnlyFor stl14 libc sys_types_only pthreads)
  include(${CMAKE_BINARY_DIR}/ClangModules.cmake)

elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  # TODO
  message(FATAL_ERROR "Can't build with gcc, we want to test clang")
endif()


set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

include_directories(inc)

find_package(PythonLibs REQUIRED)
include_directories(${PYTHON_INCLUDE_DIRS})

add_library(cms-test OBJECT cms.cpp)
add_library(boost-test OBJECT compile.cpp)
