project(ClangModulesCMake)
cmake_minimum_required(VERSION 3.0)

enable_testing()

set(SHOULD_CHECK CHECK)
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  set(SHOULD_CHECK SKIP_CHECKS)
endif()

file(GLOB tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/*")
foreach(t ${tests})
  get_filename_component(test_name "${t}" NAME)
  add_test(NAME ${test_name} COMMAND bash -x "${CMAKE_SOURCE_DIR}/run_test.sh" "${CMAKE_C_COMPILER}" "${CMAKE_CXX_COMPILER}" ${SHOULD_CHECK} "${t}")
endforeach()
