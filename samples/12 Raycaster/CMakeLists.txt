#===============================================================================
#
# Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(sample-raycaster CXX)
set(CMAKE_CXX_STANDARD 20)

gba_add_library_subdirectory(rom agbabi gbfs seven)

# GBA executable
add_executable(raycaster main.cpp asset_manager.cpp camera.cpp raycast_engine.iwram.cpp renderer.iwram.cpp)
set_target_properties(raycaster PROPERTIES SUFFIX ".elf")

target_compile_options(raycaster PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra -funwind-tables)
target_link_options(raycaster PRIVATE -Wl,--gc-sections)

gba_target_sources_compile_options(raycaster
    IWRAM -g0 -O3 -marm
    EWRAM -g0 -O3 -mthumb
)

target_link_libraries(raycaster PRIVATE agbabi gbfs seven)
gba_target_link_runtime_library(raycaster rom)

# Add host tools
include("${CMAKE_CURRENT_LIST_DIR}/tools/Tools.cmake")
_add_texmaker(wolftextures assets/wolftextures.png)
_add_mapper(map "${CMAKE_SOURCE_DIR}/assets/map.txt")

set(GBFS_ASSETS
    "$<TARGET_PROPERTY:wolftextures,PAL_OUTPUT>"
    "$<TARGET_PROPERTY:wolftextures,BIN_OUTPUT>"
    "$<TARGET_PROPERTY:map,BIN_OUTPUT>"
)

# GBFS assets
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    gba_add_gbfs(assets GENERATE_ASM ${GBFS_ASSETS})
    enable_language(ASM)
    target_sources(raycaster PRIVATE "$<TARGET_PROPERTY:assets,ASM_OUTPUT>")
else()
    gba_add_gbfs(assets ${GBFS_ASSETS})
    target_compile_definitions(raycaster PRIVATE ASSETS_GBFS)
endif()
set_target_properties(assets PROPERTIES SUFFIX ".gbfs")
add_dependencies(assets wolftextures map)
add_dependencies(raycaster assets)

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
