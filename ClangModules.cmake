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

function(ClangModules_GetHeadersFromModulemap)
  set(options)
  set(oneValueArgs RESULT MODULEMAP)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  file(READ ${ARG_MODULEMAP} contents)
  ClangModules_SplitByNewline(CONTENT ${contents} RESULT lines)
  foreach(line ${lines})
    string(REGEX REPLACE ".+header[ ]+\\\"([A-Za-z0-9./]+)\\\".+" "FOUND:\\1" header_match "${line}")
    if("${header_match}" MATCHES "^FOUND:")
      string(SUBSTRING "${header_match}" 6 -1 header_match)
      set(headers "${headers};${header_match}")
    endif()
  endforeach()
  set(${ARG_RESULT} "${headers}" PARENT_SCOPE)
endfunction()

function(ClangModules_CheckHeadersExist)
  set(options)
  set(oneValueArgs RESULT PATH MODULEMAP MISSING_HEADERS)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()
  ClangModules_GetHeadersFromModulemap(RESULT headers MODULEMAP ${ARG_MODULEMAP})
  set(all_headers_exist "YES")
  foreach(header ${headers})
    if(header)
      if(NOT EXISTS "${ARG_PATH}/${header}")
        set(all_headers_exist "NO")
        list(APPEND MISSING_HEADERS "${header}")
      endif()
    endif()
  endforeach()
  set(${ARG_RESULT} ${all_headers_exist} PARENT_SCOPE)
  set(${ARG_MISSING_HEADERS} "${MISSING_HEADERS}" PARENT_SCOPE)
endfunction()

function(ClangModules_MountModulemap)
  set(options)
  set(oneValueArgs RESULT VFS PATH NEW_FLAGS MODULEMAP MODULES CXX_FLAGS)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  get_filename_component(VFS_FILENAME "${ARG_MODULEMAP}" NAME)
  set(OUTPUT_VFS "${CMAKE_BINARY_DIR}/ClangModules_${VFS_FILENAME}")

  set(PATH_PLACEHOLDER "${ARG_PATH}")
  set(MODULEMAP_PLACEHOLDER "${ARG_MODULEMAP}")
  configure_file("${ARG_VFS}" "${OUTPUT_VFS}" @ONLY)

  ClangModules_CheckHeadersExist(MODULEMAP "${ARG_MODULEMAP}"
                                 PATH "${ARG_PATH}" 
                                 RESULT headers_exist
                                 MISSING_HEADERS missing_headers)

  ClangModules_GetHeadersFromModulemap(RESULT headers MODULEMAP ${ARG_MODULEMAP})

  if(headers_exist)
    set(new_args " -fmodule-map-file=${ARG_PATH}/module.modulemap -ivfsoverlay${OUTPUT_VFS} ")
    string(MD5 ARG_HASH "${ARG_CXX_FLAGS} ${new_args}")
    string(SUBSTRING ${ARG_HASH} 0 8 ARG_HASH)
    get_filename_component(ModuleName "${ARG_MODULEMAP}" NAME_WE)

    set(tmp_cache_path "${CMAKE_BINARY_DIR}/ClangModules_TmpPCMS_${ARG_HASH}")
    set(CMAKE_REQUIRED_FLAGS "${ARG_CXX_FLAGS} ${new_args} -fmodules-cache-path=${tmp_cache_path}")
    include(CheckCXXSourceCompiles)

    set(INCLUDE_LIST)
    foreach(header ${headers})
      set(INCLUDE_LIST "${INCLUDE_LIST}\n#include <${header}>")
    endforeach()

    check_cxx_source_compiles(
    "
    ${INCLUDE_LIST}
    int main() {}
    " "TestCompileModule_${ModuleName}")
    if(TestCompileModule_${ModuleName})
      set(FOUND_PCMS TRUE)
      foreach(Mod ${ARG_MODULES})
        file(GLOB_RECURSE PCMS "${tmp_cache_path}/${Mod}*.pcm")
        if(NOT PCMS)
          set(FOUND_PCMS FALSE)
        endif()
      endforeach()
      if(FOUND_PCMS)
        set(${ARG_NEW_FLAGS} "${ARG_CXX_FLAGS} ${new_args}" PARENT_SCOPE)
        set(${ARG_RESULT} YES PARENT_SCOPE)
      else()
        message(STATUS "Clang ignored modulemap for ${ModuleName}. Skipping")
        set(${ARG_RESULT} NO PARENT_SCOPE)
      endif()
    else()
      message(STATUS "Failed to compile '${tmp_cache_path}'")
      set(${ARG_RESULT} NO PARENT_SCOPE)
    endif()
    if(EXISTS "${tmp_cache_path}")
      file(REMOVE_RECURSE "${tmp_cache_path}")
    endif()
  else()
    message(STATUS "Couldn't find headers ${missing_headers} in ${ARG_PATH}")
    set(${ARG_RESULT} NO PARENT_SCOPE)
  endif()
endfunction()

function(ClangModules_SetupSTL)
  set(options)
  set(oneValueArgs CXX_FLAGS)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  string(REPLACE " " ";" cling_tmp_arg_list "${CMAKE_CXX_FLAGS}")
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${cling_tmp_arg_list} -xc++ -E -v /dev/null
                  OUTPUT_QUIET ERROR_VARIABLE CLANG_OUTPUT)

  ClangModules_SplitByNewline(CONTENT "${CLANG_OUTPUT}" RESULT CLANG_OUTPUT)

  set(INCLUDE_LIST)
  # Search clang output for include list
  set(InIncludeList NO)
  foreach(line ${CLANG_OUTPUT})
    if(${InIncludeList})
      if(${line} MATCHES "^ ")
        string(STRIP "${line}" line)
        list(APPEND INCLUDE_LIST "${line}")
      endif()
    endif()
    if(${line} MATCHES "<\\.\\.\\.>" )
      set(InIncludeList YES)
    endif()
  endforeach()

  foreach(INCLUDE_PATH ${INCLUDE_LIST})
    message(STATUS "Testing: ${INCLUDE_PATH}")
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.yaml"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl17.modulemap"
                                MODULES stl17
                                CXX_FLAGS "${ARG_CXX_FLAGS}"
                                NEW_FLAGS NEW_CXX_FLAGS
                                RESULT STL_SUCCESS)
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.yaml"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl14.modulemap"
                                MODULES stl14
                                CXX_FLAGS "${ARG_CXX_FLAGS}"
                                NEW_FLAGS NEW_CXX_FLAGS
                                RESULT STL_SUCCESS)
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.yaml"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl11.modulemap"
                                MODULES stl11
                                CXX_FLAGS "${ARG_CXX_FLAGS}"
                                NEW_FLAGS NEW_CXX_FLAGS
                                RESULT STL_SUCCESS)
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl.yaml"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl03.modulemap"
                                MODULES stl03
                                CXX_FLAGS "${ARG_CXX_FLAGS}"
                                NEW_FLAGS NEW_CXX_FLAGS
                                RESULT STL_SUCCESS)
    endif()
    if(NOT SDL2_SUCCESS)
    ClangModules_MountModulemap(VFS "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/sdl2.yaml"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/sdl2.modulemap"
                                MODULES sdl2
                                CXX_FLAGS "${ARG_CXX_FLAGS}"
                                NEW_FLAGS NEW_SDL2_FLAGS
                                RESULT SDL2_SUCCESS)
    endif()
  endforeach()


  set(NEW_CXX_FLAGS "${NEW_CXX_FLAGS} ${NEW_SDL2_FLAGS}" PARENT_SCOPE)
endfunction()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(STATUS "Configuring ClangModules")

  get_property(current_compile_options DIRECTORY PROPERTY COMPILE_OPTIONS)
  set(CXX_FLAGS "${CMAKE_CXX_FLAGS} ${current_compile_options} -fmodules -fcxx-modules -fno-implicit-module-maps")

  set(LANG_BAK $ENV{LANG})
  set(ENV{LANG} C)

  ClangModules_SetupSTL(CXX_FLAGS "${CXX_FLAGS}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${NEW_CXX_FLAGS} -fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms")

  set(ENV{LANG} ${LANG_BAK})

endif()
