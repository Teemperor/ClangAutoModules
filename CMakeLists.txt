project(boost-compile)
cmake_minimum_required(VERSION 3.0)

option(use_modules "Build with C++ modules" On)
if(use_modules MATCHES print)
  set(textual_check On)
  set(use_modules On)
endif()

option(cms "Test CMS version of boost" On)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" AND use_modules)
  # using Clang
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fmodules -fcxx-modules -Xclang -fdisable-module-hash -Xclang -fmodules-local-submodule-visibility -fmodules-cache-path=pcms")
  # no autopr warning
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations")
  # embed all headers to stress size limit
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -fmodules-embed-all-files")

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-modules-import-nested-redundant")
  if (cms)
    # CMS' boost version has a few of those...
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-module-import-in-extern-c")
  endif()

  if (textual_check)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -H -Wno-everything")
  endif()

  file(DOWNLOAD "https://github.com/Teemperor/ClangAutoModules/releases/download/0.2.2/ClangModules.cmake"
     ${CMAKE_BINARY_DIR}/ClangModules.cmake
     EXPECTED_HASH SHA256=94b68fac283bf204d48e523afb590ec4534465b1a8c0d709fc0ebb0b883782c4)
  set(ClangModules_CheckOnlyFor stl14 libc sys_types_only pthreads posix)
  include(${CMAKE_BINARY_DIR}/ClangModules.cmake)

elseif ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  # TODO
  message(FATAL_ERROR "Can't build with gcc, we want to test clang")
endif()


set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

if (cms)
  include_directories(inc-cms)
else()
  include_directories(inc)
endif()

find_package(PythonLibs REQUIRED)
include_directories(${PYTHON_INCLUDE_DIRS})

add_library(cms-test OBJECT cms.cpp)

if (cms)
  add_library(boost-test-cms OBJECT compile-cms.cpp)
else()
  add_library(boost-test OBJECT compile.cpp)
endif()

