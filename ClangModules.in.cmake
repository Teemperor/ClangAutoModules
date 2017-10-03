

find_package(PythonInterp)
if(NOT PYTHONINTERP_FOUND)
  message(STATUS "No python interpreter found. Can't setup ClangModules without!")
endif()

if(ClangModules_WithoutClang)
  set(ClangModules_ClanglessArg "--clangless")
endif()

set(ClangModules_IsClang NO)
if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  set(ClangModules_IsClang YES)
endif()

if(PYTHONINTERP_FOUND)
if(ClangModules_WithoutClang OR ClangModules_IsClang)

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

  if(NOT ClangModules_CheckOnlyFor)
    set(ClangModules_CheckOnlyFor ";")
  endif()

  if(NOT ClangModules_CustomModulemapFolders)
    set(ClangModules_CustomModulemapFolders ";")
  endif()

  if(NOT ClangModules_RequiredModules)
    set(ClangModules_RequiredModules ";")
  endif()

  if(NOT ClangModules_OutputVFSFile)
    set(ClangModules_OutputVFSFile "-")
  endif()

  set(ClangModules_ClangInvocation "${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${CMAKE_CXX_FLAGS} ${ClangModules_CURRENT_COMPILE_OPTIONS}")
  message(STATUS "Using clang invocation: ${ClangModules_ClangInvocation}")
  execute_process(COMMAND ${PYTHON_EXECUTABLE}
                 "${ClangModules_UNPACK_FOLDER}/ClangModules.py"
                 --modulemap-dir "${ClangModules_UNPACK_FOLDER}"
                 --modulemap-dir "${ClangModules_CustomModulemapFolders}"
                 --output-dir "${ClangModules_UNPACK_FOLDER}"
                 -I "${ClangModules_IncArg}"
                 ${ClangModules_ClanglessArg}
                 --vfs-output "${ClangModules_OutputVFSFile}"
                 --required-modules "${ClangModules_RequiredModules}"
                 --check-only "${ClangModules_CheckOnlyFor}"
                 --invocation "${ClangModules_ClangInvocation}"
                 WORKING_DIRECTORY "${ClangModules_UNPACK_FOLDER}"
                 RESULT_VARIABLE ClangModules_py_exitcode
                 OUTPUT_VARIABLE ClangModules_CXX_FLAGS
                 OUTPUT_STRIP_TRAILING_WHITESPACE
                 )
                 
  if(NOT "${ClangModules_py_exitcode}" EQUAL 0)
    message(FATAL_ERROR "ClangModules failed with exit code ${ClangModules_py_exitcode}!")
  endif()

  if(ClangModules_IsClang)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ClangModules_CXX_FLAGS} -fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms")
  endif()
endif()
endif()
