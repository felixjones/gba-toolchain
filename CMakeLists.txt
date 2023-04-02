cmake_minimum_required(VERSION 3.18)

include(FetchContent)

FetchContent_declare(gcem
    GIT_REPOSITORY "https://github.com/kthohr/gcem.git"
    GIT_TAG "v1.16.0"
    CMAKE_ARGS --toolchain "${CMAKE_TOOLCHAIN_FILE}"
)
FetchContent_MakeAvailable(gcem)

project(agb_devkit CXX)
find_package(agbabi)
find_package(librom)
find_package(libseven)

add_executable(my_game main.cpp)
target_compile_options(my_game PRIVATE -mthumb -Wpedantic -Wall -Wextra -Wconversion)
target_link_libraries(my_game PRIVATE agbabi librom libseven gcem)

target_compile_features(my_game PRIVATE cxx_std_20)

set_target_properties(my_game PROPERTIES
    ROM_TITLE "Wall 3D"
    ROM_ID AW3E
    ROM_MAKER FJ
    ROM_VERSION 1
)

if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
    install_rom(my_game)
endif()
