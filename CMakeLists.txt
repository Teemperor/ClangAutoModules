project(ClangModulesCMake)
cmake_minimum_required(VERSION 3.0)

enable_testing()

set(SHOULD_CHECK CHECK)
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  set(SHOULD_CHECK SKIP_CHECKS)
endif()

file(GLOB tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/compilation/*")
if(NOT tests)
  message(FATAL_ERROR "No tests found, this should never happen")
endif()
foreach(t ${tests})
  get_filename_component(test_name "${t}" NAME)

  if(EXISTS "${t}/EXPECTED_ERROR")
    add_test(NAME compile-expected-fail:${test_name}
           COMMAND bash -x "${CMAKE_SOURCE_DIR}/scripts/run_test_neg.sh" "${CMAKE_SOURCE_DIR}/scripts/run_test.sh" "${CMAKE_C_COMPILER}" "${CMAKE_CXX_COMPILER}" ${SHOULD_CHECK} "${t}")
  else()
    add_test(NAME compile:${test_name}
           COMMAND bash -x "${CMAKE_SOURCE_DIR}/scripts/run_test.sh" "${CMAKE_C_COMPILER}" "${CMAKE_CXX_COMPILER}" ${SHOULD_CHECK} "${t}")
  endif()
endforeach()

file(GLOB checks "${CMAKE_CURRENT_SOURCE_DIR}/tests/checks/*.py")
if(NOT checks)
  message(FATAL_ERROR "No checks found, this should never happen")
endif()
foreach(c ${checks})
  get_filename_component(check_name "${c}" NAME_WE)
  set(check_data "${CMAKE_CURRENT_SOURCE_DIR}/tests/checks/${check_name}-data")
  set(check_dir "${CMAKE_BINARY_DIR}/${check_name}")
  if(EXISTS "${check_data}")
    add_test(NAME check:${check_name}
            COMMAND ${CMAKE_COMMAND} -E remove_directory "${check_dir}"
            COMMAND ${CMAKE_COMMAND} -E copy_directory "${check_data}" "${check_dir}"
            COMMAND python "${c}" "${CMAKE_CURRENT_SOURCE_DIR}"
            WORKING_DIRECTORY "${check_dir}")
  else()
    add_test(NAME check:${check_name}
            COMMAND python "${c}" "${CMAKE_CURRENT_SOURCE_DIR}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
endforeach()
