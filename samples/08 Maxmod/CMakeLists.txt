#===============================================================================
#
# Sample Maxmod GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(sample-maxmod C)

gba_add_library_subdirectory(rom tonc maxmod gbfs)

# Add soundbank
gba_add_maxmod_soundbank(soundbank GENERATE_HEADER
    maxmod_data/Ambulance.wav
    maxmod_data/Boom.wav
    maxmod_data/FlatOutLies.mod
)
set_target_properties(soundbank PROPERTIES SUFFIX ".bin") # Output with .bin extension

# Add GBFS archive
if(CMAKE_BUILD_TYPE STREQUAL Debug)
    gba_add_gbfs(assets GENERATE_ASM soundbank)
    enable_language(ASM)

    add_executable(helloMaxmod main.c "$<TARGET_PROPERTY:assets,ASM_OUTPUT>")
else()
    gba_add_gbfs(assets soundbank)
    add_executable(helloMaxmod main.c)

    target_compile_definitions(helloMaxmod PRIVATE ASSETS_GBFS)
endif()

add_dependencies(assets soundbank)
add_dependencies(helloMaxmod assets)

set_target_properties(assets PROPERTIES SUFFIX ".gbfs")
set_target_properties(helloMaxmod PROPERTIES SUFFIX ".elf")

target_compile_options(helloMaxmod PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(helloMaxmod PRIVATE -Wl,--gc-sections)

gba_target_sources_compile_options(helloMaxmod
    IWRAM -g0 -Os -marm
    EWRAM -g0 -O3 -mthumb
)

# Include the directory where soundbank compiles to
target_include_directories(helloMaxmod PRIVATE "${CMAKE_BINARY_DIR}")

target_link_libraries(helloMaxmod PRIVATE rom tonc maxmod gbfs)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    gba_target_objcopy(helloMaxmod FIX_HEADER)
else()
    gba_target_objcopy(helloMaxmod FIX_HEADER PAD 256 OUTPUT helloMaxmod_noassets.gba)
    add_custom_command(TARGET helloMaxmod POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E cat helloMaxmod_noassets.gba assets.gbfs ">" helloMaxmod.gba
    )
endif()
