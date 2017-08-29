cmake_minimum_required(VERSION 3.1)

set(ClangModules_UNPACK_FOLDER "${CMAKE_BINARY_DIR}")

function(ClangModules_UnpackFiles)
##UNPACK_PLACEHOLDER
endfunction()

## ClangModules_CheckHeaders(INC_DIR <path> HEADERS <header1> <headern> RESULT <output_variable>)
##   `-INC_DIR - The directory to check for if the headers exist.
##   `-HEADERS - List of relative path to header files that the function should check for.
##   `-RESULT  - Set to YES if all headers exist, otherwise set ot NO (RETURN VAR).
##
## Check if all given headers exist in the given path.
##
## Example; ClangModules_CheckHeaders(INC_DIR /usr/include HEADERS stdio.h SDL2/SDL2.h RESULT HEADERS_EXIST)
function(ClangModules_CheckHeaders)
  set(OPTIONS)
  set(ONE_VALUE_ARGS INC_DIR RESULT)
  set(MULTI_VALUE_ARGS HEADERS)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN})
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  set(RESULT YES)
  foreach(HEADER ${ARG_HEADERS})
    string(STRIP "${HEADER}" HEADER)
    if(NOT EXISTS "${ARG_INC_DIR}/${HEADER}")
      set(RESULT NO)
    endif()
  endforeach()

  set(${ARG_RESULT} ${RESULT} PARENT_SCOPE)
endfunction()

## ClangModules_SplitByNewline(CONTENT <string> RESULT <output_variable>)
##   `-CONTENT - The string that should be split.
##   `-RESULT  - Set to the list of lines in CONTENT (RETURN_VAR).
##
## Splits a string into lines
##
## Example; ClangModules_SplitByNewline(INC_DIR "OneLine\nAnotherLine" RESULT HEADERS_EXIST)
function(ClangModules_SplitByNewline)
  set(OPTIONS)
  set(ONE_VALUE_ARGS RESULT)
  set(MULTI_VALUE_ARGS CONTENT)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  STRING(REGEX REPLACE "\n" ";" LINES "${ARG_CONTENT}")

  set(${ARG_RESULT} ${LINES} PARENT_SCOPE)
endfunction()

## ClangModules_GetHeadersFromModulemap(MODULEMAP <path> RESULT <output_variable>)
##   `-MODULEMAP - Path to the modulemap that should be parsed.
##   `-RESULT  - List of headers in the modulemap.
##
## Reads a modulemap and returns a list of headers this modulemap references.
## Note that the parsing is really basic and for correct results each line should
## only have one `header "XXX.h"` directive.
##
## Example; ClangModules_GetHeadersFromModulemap(MODULEMAP test/module.modulemap RESULT list_of_headers)
function(ClangModules_GetHeadersFromModulemap)
  set(OPTIONS)
  set(ONE_VALUE_ARGS RESULT MODULEMAP)
  set(MULTI_VALUE_ARGS)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  # TODO: Handle commented out lines?
  file(READ ${ARG_MODULEMAP} CONTENTS)
  ClangModules_SplitByNewline(CONTENT ${CONTENTS} RESULT LINES)
  foreach(LINE ${LINES})
    string(REGEX REPLACE ".+header[ ]+\\\"([_A-Za-z0-9./]+)\\\".+" "FOUND:\\1" HEADER_MATCH "${LINE}")
    if("${HEADER_MATCH}" MATCHES "^FOUND:")
      string(SUBSTRING "${HEADER_MATCH}" 6 -1 HEADER_MATCH)
      set(HEADERS "${HEADERS};${HEADER_MATCH}")
    endif()
  endforeach()
  set(${ARG_RESULT} "${HEADERS}" PARENT_SCOPE)
endfunction()

function(ClangModules_CheckHeadersExist)
  set(OPTIONS)
  set(ONE_VALUE_ARGS RESULT PATH MODULEMAP MISSING_HEADERS)
  set(MULTI_VALUE_ARGS)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()
  ClangModules_GetHeadersFromModulemap(RESULT HEADERS MODULEMAP ${ARG_MODULEMAP})
  set(ALL_HEADERS_EXIST "YES")
  foreach(HEADER ${HEADERS})
    if(HEADER)
      if(NOT EXISTS "${ARG_PATH}/${HEADER}")
        set(ALL_HEADERS_EXIST "NO")
        list(APPEND MISSING_HEADERS "${HEADER}")
      endif()
    endif()
  endforeach()
  set(${ARG_RESULT} ${ALL_HEADERS_EXIST} PARENT_SCOPE)
  set(${ARG_MISSING_HEADERS} "${MISSING_HEADERS}" PARENT_SCOPE)
endfunction()

function(ClangModules_MountModulemap)
  set(OPTIONS)
  set(ONE_VALUE_ARGS RESULT TARGET_MODULEMAP PATH MODULEMAP MODULES CXX_FLAGS)
  set(MULTI_VALUE_ARGS INCLUDE_PATHS)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  ClangModules_CheckHeadersExist(MODULEMAP "${ARG_MODULEMAP}"
                                 PATH "${ARG_PATH}" 
                                 RESULT HEADERS_EXIST
                                 MISSING_HEADERS MISSING)

  ClangModules_GetHeadersFromModulemap(RESULT HEADERS MODULEMAP ${ARG_MODULEMAP})

  if(NOT HEADERS)
    message(FATAL_ERROR "Couldn't parse headers from modulemap ${ARG_MODULEMAP} for modules ${ARG_MODULES}")
  endif()

  if(HEADERS_EXIST)
    file(READ "${ARG_MODULEMAP}" MODULEMAP_CONTENTS)
    set(TARGET_EXISTS NO)
    if (EXISTS "${ARG_TARGET_MODULEMAP}")
      set(TARGET_EXISTS YES)
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_TARGET_MODULEMAP}" "${ARG_TARGET_MODULEMAP}.tmp")
    endif()

    file(APPEND "${ARG_TARGET_MODULEMAP}" "\n${MODULEMAP_CONTENTS}\n")

    get_filename_component(MODULE_NAME "${ARG_MODULEMAP}" NAME_WE)
    set(TMP_CACHE_PATH "${CMAKE_BINARY_DIR}/ClangModules_TmpPCMS_${MODULE_NAME}")
    if(EXISTS TMP_CACHE_PATH)
      file(REMOVE_RECURSE "${TMP_CACHE_PATH}")
    endif()

    set(INCLUDE_ARGS)
    foreach(INC ${ARG_INCLUDE_PATHS})
      set(INCLUDE_ARGS "${INCLUDE_ARGS} -I${INC}")
    endforeach()

    set(INCLUDE_LIST)
    foreach(HEADER ${HEADERS})
      set(INCLUDE_LIST "${INCLUDE_LIST}\n#include <${HEADER}>")
    endforeach()

    set(TEST_COMPILE_FILE "${CMAKE_BINARY_DIR}/TestCompileModule_${MODULE_NAME}.cxx")
    file(WRITE "${TEST_COMPILE_FILE}"
    "
    ${INCLUDE_LIST}
    int main() {}
    ")
    set(COMPILE_ARGS ${CMAKE_CXX_COMPILER_ARG1}
                      ${ARG_CXX_FLAGS} ${INCLUDE_ARGS} -fmodules-cache-path=${TMP_CACHE_PATH}
                      -fsyntax-only ${TEST_COMPILE_FILE})
    string(REPLACE " " ";" COMPILE_ARGS "${COMPILE_ARGS}")
    execute_process(COMMAND "${CMAKE_CXX_COMPILER}" ${COMPILE_ARGS}
                    TIMEOUT 30
                    RESULT_VARIABLE TestCompileModule_${MODULE_NAME}
                    OUTPUT_VARIABLE STDOUT
                    ERROR_VARIABLE ERROUT)
    message(STATUS "Try compiling ${MODULE_NAME}")
    if(NOT ClangModules_DEBUG)
      file(REMOVE "${TEST_COMPILE_FILE}")
    endif()
    if(TestCompileModule_${MODULE_NAME} STREQUAL "0")
      set(FOUND_PCMS TRUE)
      foreach(CXX_MODULE ${ARG_MODULES})
        file(GLOB_RECURSE PCMS "${TMP_CACHE_PATH}/${CXX_MODULE}*.pcm")
        if(NOT PCMS)
          set(FOUND_PCMS FALSE)
        endif()
      endforeach()
      if(FOUND_PCMS)
        message(STATUS "Clang was able to compile module ${MODULE_NAME}!")
        set(TMP_RESULT YES)
      else()
        message(STATUS "Clang ignored modulemap for ${MODULE_NAME}. Skipping")
        set(TMP_RESULT NO)
      endif()
    else()
      if(ClangModules_DEBUG)
        message(STATUS "CMD: ${CMAKE_CXX_COMPILER} ${COMPILE_ARGS}")
        message(STATUS "STD: ${STDOUT}")
        message(STATUS "ERR: ${ERROUT}")
        message(STATUS "RES: ${TestCompileModule_${MODULE_NAME}}")
      endif()
      message(STATUS "Failed to compile module '${MODULE_NAME}'")
      set(TMP_RESULT NO)
    endif()
    if(EXISTS "${TMP_CACHE_PATH}")
      file(REMOVE_RECURSE "${TMP_CACHE_PATH}")
    endif()

    # Restore original modulemap on failure
    if (NOT TMP_RESULT)
      if(TARGET_EXISTS)
        execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_TARGET_MODULEMAP}.tmp" "${ARG_TARGET_MODULEMAP}")
      else()
        file(REMOVE "${ARG_TARGET_MODULEMAP}")
      endif()
    endif()
  else()
    if(ClangModules_DEBUG)
      message(STATUS "DEBUG: Couldn't find headers ${MISSING} in ${ARG_PATH} for ${ARG_MODULES}")
    endif()
    set(TMP_RESULT NO)
  endif()
  set(${ARG_RESULT} ${TMP_RESULT} PARENT_SCOPE)
endfunction()

set(ClangModules_FINAL_MODULEMAP_PATH)
set(ClangModules_INCLUDE_PATH)
set(ClangModules_INCLUDE_LIST)
set(ClangModules_FINAL_TEST_FLAGS)
function(ClangModules_Intern_SetupModulemaps)
  set(OPTIONS)
  set(ONE_VALUE_ARGS MODULE RESULT)
  set(MULTI_VALUE_ARGS MODULEMAP)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()
  if(NOT ARG_MODULEMAP)
    set(ARG_MODULEMAP "${ARG_MODULE}")
  endif()
  ClangModules_MountModulemap(TARGET_MODULEMAP "${ClangModules_FINAL_MODULEMAP_PATH}"
                              PATH "${ClangModules_INCLUDE_PATH}"
                              INCLUDE_PATHS "${ClangModules_INCLUDE_LIST}"
                              MODULEMAP "${ClangModules_UNPACK_FOLDER}/${ARG_MODULEMAP}.modulemap"
                              MODULES ${ARG_MODULE}
                              CXX_FLAGS "${ClangModules_FINAL_TEST_FLAGS}"
                              RESULT TMP_SUCCESS)
  if(TMP_SUCCESS)
    set(SUCCESS "YES" PARENT_SCOPE)
    set(${ARG_RESULT} "YES" PARENT_SCOPE)
  endif()
endfunction()


function(ClangModules_SetupModulemaps)
  set(OPTIONS)
  set(ONE_VALUE_ARGS CXX_FLAGS VFS NEW_FLAGS)
  set(MULTI_VALUE_ARGS)
  cmake_parse_arguments(ARG "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  string(REPLACE " " ";" cling_tmp_arg_list "${CMAKE_CXX_FLAGS}")
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} ${cling_tmp_arg_list} -xc++ -E -v /dev/null
                  OUTPUT_QUIET ERROR_VARIABLE CLANG_OUTPUT)

  ClangModules_SplitByNewline(CONTENT "${CLANG_OUTPUT}" RESULT CLANG_OUTPUT)

  set(INCLUDE_LIST)
  # Search clang output for include list
  set(IN_INCLUDE_LIST NO)
  foreach(LINE ${CLANG_OUTPUT})
    if(${IN_INCLUDE_LIST})
      if(${LINE} MATCHES "^ ")
        string(STRIP "${LINE}" LINE)
        list(APPEND INCLUDE_LIST "${LINE}")
      endif()
    endif()
    if(${LINE} MATCHES "<\\.\\.\\.>" )
      set(IN_INCLUDE_LIST YES)
    endif()
  endforeach()

  get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
  foreach(dir ${dirs})
    list(INSERT INCLUDE_LIST 0 "${dir}")
  endforeach()

  set(EXTRA_INC_DIRS_FLAGS "")

  # FIXME: This needs testing...
  # Create an empty dummy list to make the list(REVERSE ...) work
  if(NOT ClangModules_EXTRA_INC_DIRS)
    set(ClangModules_EXTRA_INC_DIRS "")
  endif()
  list(REVERSE ClangModules_EXTRA_INC_DIRS)
  foreach(dir ${ClangModules_EXTRA_INC_DIRS})
    list(INSERT INCLUDE_LIST 0 "${dir}")
  set(EXTRA_INC_DIRS_FLAGS "-I${dir} ${EXTRA_INC_DIRS_FLAGS}")
  endforeach()
  list(REVERSE ClangModules_EXTRA_INC_DIRS)

  set(NEW_FLAGS "")

  set(MODULEMAP_ID 1)

  set(FIRST_ITER YES)
  foreach(INCLUDE_PATH ${INCLUDE_LIST})
    message(STATUS "Testing: ${INCLUDE_PATH}")

    math(EXPR MODULEMAP_ID "${MODULEMAP_ID}+1")
    set(FINAL_MODULEMAP_PATH "${CMAKE_BINARY_DIR}/ClangModules-${MODULEMAP_ID}.modulemap")

    execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}" "${ARG_VFS}.tmp")
    if(NOT FIRST_ITER)
      file(APPEND ${ARG_VFS} ",\n")
    endif()
    file(APPEND ${ARG_VFS} "  { 'name': '${INCLUDE_PATH}', 'type': 'directory',\n")
    file(APPEND ${ARG_VFS} "    'contents':\n")
    file(APPEND ${ARG_VFS} "      [{ 'name': 'module.modulemap', 'type': 'file',\n")
    file(APPEND ${ARG_VFS} "        'external-contents': '${FINAL_MODULEMAP_PATH}'\n")
    file(APPEND ${ARG_VFS} "      }]\n")
    file(APPEND ${ARG_VFS} "  }\n")

    execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}" "${ARG_VFS}.unfinished")
    #finalize VFS
    file(APPEND ${ARG_VFS} "]}\n")

    set(FIRST_ITER NO)

    set(TEST_NEW_FLAG "-fmodule-map-file=${INCLUDE_PATH}/module.modulemap")
    set(FINAL_TEST_FLAGS "${ARG_CXX_FLAGS} ${TEST_NEW_FLAG}")

    set(SUCCESS NO)
    set(TMP_SUCCESS NO)

    set(ClangModules_FINAL_MODULEMAP_PATH "${FINAL_MODULEMAP_PATH}")
    set(ClangModules_INCLUDE_PATH "${INCLUDE_PATH}")
    set(ClangModules_INCLUDE_LIST "${INCLUDE_LIST}")
    set(ClangModules_FINAL_TEST_FLAGS "${FINAL_TEST_FLAGS}")

    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${FINAL_MODULEMAP_PATH}"
                                PATH "${INCLUDE_PATH}"
                                INCLUDE_PATHS "${INCLUDE_LIST}"
                                MODULEMAP "${ClangModules_UNPACK_FOLDER}/stl17.modulemap"
                                MODULES stl17
                                CXX_FLAGS "${FINAL_TEST_FLAGS}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(STL_SUCCESS "YES")
      endif()
    endif()
    if(NOT STL_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE stl14         RESULT STL_SUCCESS)
    endif()
    if(NOT STL_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE stl11         RESULT STL_SUCCESS)
    endif()
    if(NOT STL_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE stl03         RESULT STL_SUCCESS)
    endif()
    if(NOT BOOST_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE boost         RESULT BOOST_SUCCESS      MODULEMAP boost_min)
    endif()
    if(NOT SDL2_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE sdl2          RESULT SDL2_SUCCESS)
    endif()
    if(NOT LINUX_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE linux         RESULT LINUX_SUCCESS)
    endif()
    if(NOT TINYXML_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE tinyxml       RESULT TINYXML_SUCCESS)
    endif()
    if(NOT TINYXML2_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE tinyxml2      RESULT TINYXML2_SUCCESS)
    endif()
    if(NOT BULLET_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE bullet        RESULT BULLET_SUCCESS)
    endif()
    if(NOT BULLET_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE bullet        RESULT BULLET_SUCCESS    MODULEMAP bullet_old)
    endif()
    if(NOT GLOG_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE glog          RESULT GLOG_SUCCESS)
    endif()
    if(NOT EIGEN3_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE eigen3        RESULT EIGEN3_SUCCESS    MODULEMAP eigen3_big)
    endif()
    if(NOT EIGEN3_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE eigen3        RESULT EIGEN3_SUCCESS    MODULEMAP eigen3_min)
    endif()
    if(NOT SFML_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE sfml          RESULT SFML_SUCCESS      MODULEMAP sfml_newer)
    endif()
    if(NOT SFML_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE sfml          RESULT SFML_SUCCESS)
    endif()
    if(NOT GTEST_SUCCESS)
      ClangModules_Intern_SetupModulemaps(MODULE gtest         RESULT GTEST_SUCCESS)
    endif()

    if(SUCCESS)
      set(NEW_FLAGS "${NEW_FLAGS} ${TEST_NEW_FLAG}")
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}.unfinished" "${ARG_VFS}")
    else()
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}.tmp" "${ARG_VFS}")
    endif()
  endforeach()
  set(${ARG_NEW_FLAGS} "${NEW_FLAGS}" PARENT_SCOPE)
endfunction()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(STATUS "Configuring ClangModules")
  ClangModules_UnpackFiles()

  set(ClangModules_VFS_FILE "${CMAKE_BINARY_DIR}/ClangModulesVFS.yaml")
  file(WRITE ${ClangModules_VFS_FILE} "{ 'version': 0, 'roots': [\n")
  get_property(ClangModules_CURRENT_COMPILE_OPTIONS DIRECTORY PROPERTY COMPILE_OPTIONS)
  set(ClangModules_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ClangModules_CURRENT_COMPILE_OPTIONS} -fmodules -fcxx-modules -Xclang -fmodules-local-submodule-visibility ")
  set(ClangModules_CXX_FLAGS "${ClangModules_CXX_FLAGS} -fno-implicit-module-maps -ivfsoverlay${ClangModules_VFS_FILE}")

  set(ClangModules_LANG_BAK $ENV{LANG})
  set(ENV{LANG} C)

  ClangModules_SetupModulemaps(CXX_FLAGS "${ClangModules_CXX_FLAGS}" VFS "${ClangModules_VFS_FILE}" NEW_FLAGS ClangModules_NEW_FLAGS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ClangModules_CXX_FLAGS} ${ClangModules_NEW_FLAGS} -fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms")

  file(APPEND ${ClangModules_VFS_FILE} "]}\n")
  set(ENV{LANG} ${ClangModules_LANG_BAK})

endif()
