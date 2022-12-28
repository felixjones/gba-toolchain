cmake_minimum_required(VERSION 3.18)
project(agb_devkit CXX)

set(CMAKE_CXX_STANDARD 17)

add_subdirectory(lib/rom)
add_executable(agb_devkit main.cpp)
target_link_libraries(agb_devkit PRIVATE rom)
