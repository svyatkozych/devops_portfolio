cmake_minimum_required(VERSION 3.20)
project(logparser LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

option(STATIC_BUILD "Link statically (for the scratch Docker image)" OFF)

add_executable(logparser src/main.cpp)
target_compile_options(logparser PRIVATE -Wall -Wextra -Wpedantic)
if(STATIC_BUILD)
  target_link_options(logparser PRIVATE -static)
endif()

enable_testing()
set(TOOLKIT_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../..)

add_test(NAME sample_log
  COMMAND sh -c "$<TARGET_FILE:logparser> ${TOOLKIT_ROOT}/tests/data/access.log | diff - ${TOOLKIT_ROOT}/tests/data/access.expected.txt")
add_test(NAME top_option
  COMMAND sh -c "$<TARGET_FILE:logparser> -n 1 ${TOOLKIT_ROOT}/tests/data/access.log | grep -q 203.0.113.5")
add_test(NAME missing_file
  COMMAND sh -c "! $<TARGET_FILE:logparser> /nonexistent.log 2>/dev/null")
add_test(NAME no_arguments
  COMMAND sh -c "$<TARGET_FILE:logparser> 2>/dev/null; test $? -eq 2")
