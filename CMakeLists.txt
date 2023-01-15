cmake_minimum_required(VERSION 3.18)

project(agb_devkit CXX)
find_package(librom)

add_executable(my_game main.cpp render.iwram.cpp)
target_compile_options(my_game PRIVATE -mthumb -Wpedantic -Wall -Wextra -Wconversion)
target_link_libraries(my_game PRIVATE librom)

set_source_files_properties(render.iwram.cpp PROPERTIES COMPILE_FLAGS "-marm -O3")

set_target_properties(my_game PROPERTIES
    ROM_TITLE "My Game"
    ROM_ID AMGE
    ROM_MAKER FJ
    ROM_VERSION 0x1
)

if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
    install_rom(my_game)
endif()
