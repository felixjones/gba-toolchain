cmake_minimum_required(VERSION 3.18)

project(agb_devkit ASM CXX)
find_package(agbabi)
find_package(librom)
find_package(tonclib)
find_package(gbfs)

add_executable(my_game main.cpp render.iwram.cpp)
target_compile_options(my_game PRIVATE -mthumb -Wpedantic -Wall -Wextra -Wconversion)
target_link_libraries(my_game PRIVATE agbabi librom tonclib gbfs)

set_source_files_properties(render.iwram.cpp PROPERTIES COMPILE_FLAGS "-marm -O3")

set_target_properties(my_game PROPERTIES
    ROM_TITLE "My Game"
    ROM_ID AMGE
    ROM_MAKER FJ
    ROM_VERSION 1
)

if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
    add_gbfs_archive(assets ASM test.txt)
    set_target_properties(assets PROPERTIES
        OUTPUT_NAME resources
    )
    set_source_files_properties(resources.s PROPERTIES GENERATED TRUE)

    add_dependencies(my_game assets)
    target_sources(my_game PRIVATE resources.s)

    install_rom(my_game)
endif()
