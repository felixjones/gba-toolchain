#===============================================================================
#
# Superfamiconv project
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(12-Superfamiconv-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(superfamiconv REQUIRED)

add_superfamiconv_library(sprite PALETTE TILES
        PALETTE_SPRITE_MODE
        TILES_SPRITE_MODE
        graphics/metr.png
)

add_superfamiconv_library(map PALETTE TILES MAP
        MAP_WIDTH 64
        graphics/brin.png
)

add_executable(12-Superfamiconv
        main.c
)

target_link_libraries(12-Superfamiconv PRIVATE
        librom tonclib
        sprite map
)

install_rom(12-Superfamiconv)
