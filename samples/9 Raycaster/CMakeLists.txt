#===============================================================================
#
# Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(sample-raycaster C CXX)
set (CMAKE_CXX_STANDARD 20)

gba_add_library_subdirectory(rom agbabi gbfs)

# Run host tools
include("${CMAKE_CURRENT_LIST_DIR}/tools/Tools.cmake")
_texmaker("${CMAKE_SOURCE_DIR}/assets/wolftextures.png")
_mapper("${CMAKE_SOURCE_DIR}/assets/map.txt")

# GBFS assets
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    gba_add_gbfs(assets GENERATE_ASM "assets/wolftextures.pal" "assets/wolftextures.bin" "assets/map.bin")
    enable_language(ASM)
    add_executable(raycaster main.c renderer.cpp raycaster.iwram.cpp texmapper.iwram.cpp "$<TARGET_PROPERTY:assets,ASM_OUTPUT>")
else()
    gba_add_gbfs(assets "assets/wolftextures.pal" "assets/wolftextures.bin" "assets/map.bin")
    add_executable(raycaster main.c renderer.cpp raycaster.iwram.cpp texmapper.iwram.cpp)
    target_compile_definitions(raycaster PRIVATE ASSETS_GBFS)
endif()

set_target_properties(assets PROPERTIES SUFFIX ".gbfs")

# GBA executable
set_target_properties(raycaster PROPERTIES SUFFIX ".elf")

target_compile_options(raycaster PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(raycaster PRIVATE -Wl,--gc-sections)

gba_target_sources_compile_options(raycaster
    IWRAM -g0 -O3 -marm
    EWRAM -g0 -O3 -mthumb
)

target_link_libraries(raycaster PRIVATE agbabi gbfs m)
gba_target_link_runtime_library(raycaster rom)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    # Debug build can just fix header
    gba_target_objcopy(raycaster FIX_HEADER)
else()
    # Release build needs to pad the binary and output an asset-less version
    gba_target_objcopy(raycaster FIX_HEADER PAD 256 OUTPUT raycaster_noassets.gba)

    # Concatenate with helloGbfs_noassets.gba with assets.gbfs into hellGbfs.gba
    add_custom_command(TARGET raycaster POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E cat raycaster_noassets.gba assets.gbfs ">" raycaster.gba
    )
endif()
