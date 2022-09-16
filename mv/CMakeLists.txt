cmake_minimum_required(VERSION 3.4)

project(mv
  DESCRIPTION "An implementation of mv in C++"
  LANGUAGES CXX
)

add_executable(mv src/main.cpp)
set_target_properties(mv
  PROPERTIES
    CXX_STANDARD 20
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../bin/"
)

find_package(fmt)
target_link_libraries(mv fmt::fmt)
