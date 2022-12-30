cmake_minimum_required(VERSION 3.18)

project(agb_devkit CXX)
add_subdirectory(lib/rom)

add_executable(my_game main.cpp)
target_compile_options(my_game PRIVATE -mthumb -Wall -Wextra)
target_link_libraries(my_game PRIVATE librom)

if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
    install_rom(my_game)
endif()
