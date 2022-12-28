cmake_minimum_required(VERSION 3.18)

project(agb_devkit CXX)
add_subdirectory(lib/rom)

add_executable(my_game main.cpp)
target_link_libraries(my_game PRIVATE librom)
