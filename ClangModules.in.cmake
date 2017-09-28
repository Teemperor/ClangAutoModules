

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")

  cmake_minimum_required(VERSION 3.1)

  set(ClangModules_UNPACK_FOLDER "${CMAKE_BINARY_DIR}")

  function(ClangModules_UnpackFiles)
  ##UNPACK_PLACEHOLDER
  endfunction()

  message(STATUS "Configuring ClangModules")
  ClangModules_UnpackFiles()
  
  get_property(ClangModules_CURRENT_COMPILE_OPTIONS DIRECTORY PROPERTY COMPILE_OPTIONS)
  
  set(ClangModules_IncArg ":")
  get_property(ClangModules_dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
  foreach(inc ${ClangModules_dirs})
    set(ClangModules_IncArg "${ClangModules_IncArg}:${inc}")
  endforeach()

  if(NOT ClangModules_CustomModulemapFolders)
    set(ClangModules_CustomModulemapFolders ";")
  endif()
  set(ClangModules_ClangInvocation "${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${CMAKE_CXX_FLAGS} ${ClangModules_CURRENT_COMPILE_OPTIONS}")
  message(STATUS "Using clang invocation: ${ClangModules_ClangInvocation}")
  message(STATUS "Using clang invocation: ${ClangModules_IncArg}")
  execute_process(COMMAND python "${ClangModules_UNPACK_FOLDER}/ClangModules.py"
                 --modulemap-dir "${ClangModules_UNPACK_FOLDER}"
                 --modulemap-dir "${ClangModules_CustomModulemapFolders}"
                 --output-dir "${ClangModules_UNPACK_FOLDER}"
                 -I "${ClangModules_IncArg}"
                 --invocation "${ClangModules_ClangInvocation}"
                 WORKING_DIRECTORY "${ClangModules_UNPACK_FOLDER}"
                 RESULT_VARIABLE ClangModules_py_exitcode
                 OUTPUT_VARIABLE ClangModules_CXX_FLAGS
                 #ERROR_VARIABLE ClangModules_py_stderr
                 OUTPUT_STRIP_TRAILING_WHITESPACE
                 #ERROR_STRIP_TRAILING_WHITESPACE
                 )
                 
  message(STATUS "Exit: ${ClangModules_py_exitcode}")
  message(STATUS "std: ${ClangModules_CXX_FLAGS}")
  #message(STATUS "err: ${ClangModules_py_stderr}")

  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ClangModules_CXX_FLAGS} -fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms")
endif()
