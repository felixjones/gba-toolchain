cmake_minimum_required(VERSION 3.18)

project(agb_devkit CXX)
add_subdirectory(lib/rom)

include(ExternalProject)
ExternalProject_Add(libagbabi
    GIT_REPOSITORY "https://github.com/felixjones/agbabi.git"
    GIT_TAG "2.0"
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/lib/agbabi"
    CMAKE_ARGS --toolchain=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}
)
find_library(AGBABI agbabi)
include_directories("lib/agbabi/include")

add_executable(my_game main.cpp render.iwram.cpp)
target_compile_options(my_game PRIVATE -mthumb -Wpedantic -Wall -Wextra -Wconversion)
target_link_libraries(my_game PRIVATE librom ${AGBABI})

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
