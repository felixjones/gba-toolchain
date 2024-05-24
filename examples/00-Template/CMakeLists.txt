#===============================================================================
#
# Template project
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(template-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(grit REQUIRED)

add_executable(template
        main.c
)

set_target_properties(template PROPERTIES
        ROM_TITLE "my game"
        ROM_VERSION 1
)

add_grit_library(sprite
        GRAPHICS_BIT_DEPTH 4
        AREA_RIGHT 64
        graphics/metr.png
)

add_grit_library(map
        GRAPHICS_BIT_DEPTH 4
        MAP_LAYOUT REGULAR_SBB
        graphics/brin.png
)

target_link_libraries(template PRIVATE
        librom tonclib
        sprite map
)

install_rom(template)
