cmake_minimum_required(VERSION 3.1)

## ClangModules_CheckHeaders(INC_DIR <path> HEADERS <header1> <headern> RESULT <output_variable>)
##   `-INC_DIR - The directory to check for if the headers exist.
##   `-HEADERS - List of relative path to header files that the function should check for.
##   `-RESULT  - Set to YES if all headers exist, otherwise set ot NO (RETURN VAR).
##
## Check if all given headers exist in the given path.
##
## Example; ClangModules_CheckHeaders(INC_DIR /usr/include HEADERS stdio.h SDL2/SDL2.h RESULT headers_exist)
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

## ClangModules_SplitByNewline(CONTENT <string> RESULT <output_variable>)
##   `-CONTENT - The string that should be split.
##   `-RESULT  - Set to the list of lines in CONTENT (RETURN_VAR).
##
## Splits a string into lines
##
## Example; ClangModules_SplitByNewline(INC_DIR "OneLine\nAnotherLine" RESULT headers_exist)
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
  set(options)
  set(oneValueArgs RESULT MODULEMAP)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  # TODO: Handle commented out lines?
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
  set(oneValueArgs RESULT TARGET_MODULEMAP PATH MODULEMAP MODULES CXX_FLAGS)
  set(multiValueArgs)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )
  if (ARG_UNPARSED_ARGUMENTS)
    message(ERROR "Unparsed args: ${ARG_UNPARSED_ARGUMENTS}")
  endif()

  ClangModules_CheckHeadersExist(MODULEMAP "${ARG_MODULEMAP}"
                                 PATH "${ARG_PATH}" 
                                 RESULT headers_exist
                                 MISSING_HEADERS missing_headers)

  ClangModules_GetHeadersFromModulemap(RESULT headers MODULEMAP ${ARG_MODULEMAP})

  if(headers_exist)
    file(READ "${ARG_MODULEMAP}" modulemap_contents)
    set(TARGET_EXISTS NO)
    if (EXISTS "${ARG_TARGET_MODULEMAP}")
      set(TARGET_EXISTS YES)
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_TARGET_MODULEMAP}" "${ARG_TARGET_MODULEMAP}.tmp")
    endif()

    file(APPEND "${ARG_TARGET_MODULEMAP}" "\n${modulemap_contents}\n")

    get_filename_component(ModuleName "${ARG_MODULEMAP}" NAME_WE)
    set(tmp_cache_path "${CMAKE_BINARY_DIR}/ClangModules_TmpPCMS_${ModuleName}")
    set(CMAKE_REQUIRED_FLAGS "${ARG_CXX_FLAGS} -fmodules-cache-path=${tmp_cache_path}")
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
        message(STATUS "Clang was able to compile module!")
        set(TMP_RESULT YES)
      else()
        message(STATUS "Clang ignored modulemap for ${ModuleName}. Skipping")
        set(TMP_RESULT NO)
      endif()
    else()
      message(STATUS "Failed to compile '${tmp_cache_path}'")
      set(TMP_RESULT NO)
    endif()
    if(EXISTS "${tmp_cache_path}")
      file(REMOVE_RECURSE "${tmp_cache_path}")
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
    #message(STATUS "Couldn't find headers ${missing_headers} in ${ARG_PATH}")
    set(TMP_RESULT NO)
  endif()
  set(${ARG_RESULT} ${TMP_RESULT} PARENT_SCOPE)
endfunction()

function(ClangModules_SetupModulemaps)
  set(options)
  set(oneValueArgs CXX_FLAGS VFS NEW_FLAGS)
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

  set(new_flags "")

  set(modulemap_id 1)

  set(first_iter YES)
  foreach(INCLUDE_PATH ${INCLUDE_LIST})
    message(STATUS "Testing: ${INCLUDE_PATH}")


    math(EXPR modulemap_id "${modulemap_id}+1")
    set(final_modulemap_path "${CMAKE_BINARY_DIR}/ClangModules-${modulemap_id}.modulemap")

    execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}" "${ARG_VFS}.tmp")
    if(NOT first_iter)
      file(APPEND ${ARG_VFS} ",\n")
    endif()
    file(APPEND ${ARG_VFS} "  { 'name': '${INCLUDE_PATH}', 'type': 'directory',\n")
    file(APPEND ${ARG_VFS} "    'contents':\n")
    file(APPEND ${ARG_VFS} "      [{ 'name': 'module.modulemap', 'type': 'file',\n")
    file(APPEND ${ARG_VFS} "        'external-contents': '${final_modulemap_path}'\n")
    file(APPEND ${ARG_VFS} "      }]\n")
    file(APPEND ${ARG_VFS} "  }\n")

    execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}" "${ARG_VFS}.unfinished")
    #finalize VFS
    file(APPEND ${ARG_VFS} "]}\n")

    set(first_iter NO)

    set(test_new_flag "-fmodule-map-file=${INCLUDE_PATH}/module.modulemap")
    set(final_test_flags "${ARG_CXX_FLAGS} ${test_new_flag}")

    set(SUCCESS NO)
    set(TMP_SUCCESS NO)

    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${final_modulemap_path}"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl17.modulemap"
                                MODULES stl17
                                CXX_FLAGS "${final_test_flags}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(STL_SUCCESS "YES")
      endif()
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${final_modulemap_path}"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl14.modulemap"
                                MODULES stl14
                                CXX_FLAGS "${final_test_flags}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(STL_SUCCESS "YES")
      endif()
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${final_modulemap_path}"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl11.modulemap"
                                MODULES stl11
                                CXX_FLAGS "${final_test_flags}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(STL_SUCCESS "YES")
      endif()
    endif()
    if(NOT STL_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${final_modulemap_path}"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/stl03.modulemap"
                                MODULES stl03
                                CXX_FLAGS "${final_test_flags}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(STL_SUCCESS "YES")
      endif()
    endif()
    if(NOT SDL2_SUCCESS)
    ClangModules_MountModulemap(TARGET_MODULEMAP "${final_modulemap_path}"
                                PATH "${INCLUDE_PATH}"
                                MODULEMAP "${CMAKE_CURRENT_SOURCE_DIR}/clang-modules/files/sdl2.modulemap"
                                MODULES sdl2
                                CXX_FLAGS "${final_test_flags}"
                                RESULT TMP_SUCCESS)
      if(TMP_SUCCESS)
        set(SUCCESS "YES")
        set(SDL2_SUCCESS "YES")
      endif()
    endif()

    if(SUCCESS)
      set(new_flags "${new_flags} ${test_new_flag}")
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}.unfinished" "${ARG_VFS}")
    else()
      execute_process(COMMAND ${CMAKE_COMMAND} -E copy "${ARG_VFS}.tmp" "${ARG_VFS}")
    endif()
  endforeach()
  set(${ARG_NEW_FLAGS} "${new_flags}" PARENT_SCOPE)
endfunction()

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  message(STATUS "Configuring ClangModules")

  set(vfs_file "${CMAKE_BINARY_DIR}/ClangModulesVFS.yaml")
  file(WRITE ${vfs_file} "{ 'version': 0, 'roots': [\n")
  get_property(current_compile_options DIRECTORY PROPERTY COMPILE_OPTIONS)
  set(CXX_FLAGS "${CMAKE_CXX_FLAGS} ${current_compile_options} -fmodules -fcxx-modules ")
  set(CXX_FLAGS "${CXX_FLAGS} -fno-implicit-module-maps -ivfsoverlay${vfs_file}")

  set(LANG_BAK $ENV{LANG})
  set(ENV{LANG} C)

  ClangModules_SetupModulemaps(CXX_FLAGS "${CXX_FLAGS}" VFS "${vfs_file}" NEW_FLAGS ClangModules_NewFlags)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXX_FLAGS} ${ClangModules_NewFlags} -fmodules-cache-path=${CMAKE_BINARY_DIR}/pcms")

  file(APPEND ${vfs_file} "]}\n")
  set(ENV{LANG} ${LANG_BAK})

endif()
