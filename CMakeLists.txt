project(ClangModulesCMake)
cmake_minimum_required(VERSION 3.0)

enable_testing()

set(SHOULD_CHECK CHECK)
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  set(SHOULD_CHECK SKIP_CHECKS)
endif()

file(GLOB tests "${CMAKE_CURRENT_SOURCE_DIR}/tests/*")
if(NOT tests)
  message(FATAL_ERROR "No tests found, this should never happen")
endif()
foreach(t ${tests})
  get_filename_component(test_name "${t}" NAME)
  add_test(NAME compile_test:${test_name}
           COMMAND bash -x "${CMAKE_SOURCE_DIR}/run_test.sh" "${CMAKE_C_COMPILER}" "${CMAKE_CXX_COMPILER}" ${SHOULD_CHECK} "${t}")
endforeach()

file(GLOB checks "${CMAKE_CURRENT_SOURCE_DIR}/checks/*.py")
if(NOT checks)
  message(FATAL_ERROR "No checks found, this should never happen")
endif()
foreach(c ${checks})
  get_filename_component(check_name "${c}" NAME_WE)
  add_test(NAME check:${check_name}
           COMMAND python "${CMAKE_CURRENT_SOURCE_DIR}/checks/${check_name}.py"
           WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
endforeach()
