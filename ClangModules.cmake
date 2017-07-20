cmake_minimum_required(VERSION 3.1)


function(ClangModules_CheckHeaders)
  set(options)
  set(oneValueArgs INC_DIR RESULT)
  set(multiValueArgs HEADERS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(RESULT YES)
  foreach(header ${ARG_HEADERS})
    string(STRIP "${header}" header)
    if(NOT EXISTS "${ARG_INC_DIR}/${header}")
      set(RESULT NO)
    endif()
  endforeach()
  
  set(${ARG_RESULT} ${RESULT} PARENT_SCOPE)
endfunction()

function(ClangModules_SplitByNewline)
  set(options)
  set(oneValueArgs RESULT)
  set(multiValueArgs CONTENT)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  STRING(REGEX REPLACE "\n" ";" TMP_VAR "${ARG_CONTENT}")
  
  set(${ARG_RESULT} ${TMP_VAR} PARENT_SCOPE)
endfunction()

function(ClangModules_MountModulemap)
  set(options)
  set(oneValueArgs VFS PATH MODULEMAP)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()
  
  get_filename_component(VFS_FILENAME "${ARG_VFS}" NAME)
  set(OUTPUT_VFS "${CMAKE_BINARY_DIR}/ClangModules_${VFS_FILENAME}")
  
  set(PATH_PLACEHOLDER "${ARG_PATH}")
  set(MODULEMAP_PLACEHOLDER "${ARG_MODULEMAP}")
  configure_file("${ARG_VFS}" "${OUTPUT_VFS}" @ONLY)
  
  add_compile_options(-fmodule-map-file=${ARG_PATH}/module.modulemap)
  add_compile_options(-ivfsoverlay${OUTPUT_VFS})

endfunction()

function(ClangModules_SetupSTL)
  string(REPLACE " " ";" cling_tmp_arg_list "${CMAKE_CXX_FLAGS}")
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${cling_tmp_arg_list} -xc++ -E -v /dev/null
                  OUTPUT_QUIET ERROR_VARIABLE CLANG_OUTPUT)
                  
  ClangModules_SplitByNewline(CONTENT "${CLANG_OUTPUT}" RESULT CLANG_OUTPUT)

  set(stl_mount_path NO)

  # Search list for clang output listing the STL locations
  set(InIncludeList NO)
  foreach(line ${CLANG_OUTPUT})
    if(${InIncludeList})
      if(${line} MATCHES "^ ")
        string(STRIP "${line}" line)
        ClangModules_CheckHeaders(INC_DIR "${line}" HEADERS "vector;list" RESULT VALID_STL)
        if(VALID_STL)
          message(STATUS "Selecting '${line}' as STL mounting path.")
          set(stl_mount_path "${line}")
        endif()
      else()
        set(InIncludeList NO)
      endif()
    endif()
    if(${line} MATCHES "<\\.\\.\\.>" )
      set(InIncludeList YES)
    endif()
  endforeach()
  
  if (stl_mount_path)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.yaml" PATH "${stl_mount_path}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.modulemap")
  endif()
endfunction()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(STATUS "Configuring ClangModules")
  #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ")
  #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} )
  
  set(LANG_BAK $ENV{LANG})
  set(ENV{LANG} C)
  
  ClangModules_SetupSTL()
  
  set(ENV{LANG} ${LANG_BAK})
  
  add_compile_options(-fmodules -fcxx-modules -fno-implicit-module-maps)
  add_compile_options(-fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms)
endif()
