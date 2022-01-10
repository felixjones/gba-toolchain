#===============================================================================
#
# Sample GBFS project for both assembly source output and appended assets
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(sample-gbfs C)

gba_add_library_subdirectory(rom tonc gbfs)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    # Debug build adds a GBFS target that outputs assembly used in the executable target
    gba_add_gbfs(assets GENERATE_ASM "hello.txt")
    # Enable ASM support (needed for our generated GBFS assembly)
    enable_language(ASM)
    # Use the GBFS assets assembly output as a source
    add_executable(helloGbfs main.c "$<TARGET_PROPERTY:assets,ASM_OUTPUT>")
else()
    # Release build doesn't use assembly source output
    gba_add_gbfs(assets "hello.txt")
    add_executable(helloGbfs main.c)
    # Define a handy macro that lets us identify appended GBFS assets
    target_compile_definitions(helloGbfs PRIVATE ASSETS_GBFS)
endif()

# Set the output file extensions for both targets
set_target_properties(assets PROPERTIES SUFFIX ".gbfs")
set_target_properties(helloGbfs PROPERTIES SUFFIX ".elf")

# helloGbfs depends on assets
add_dependencies(helloGbfs assets)
# Compile options and link libraries for helloGbfs
target_compile_options(helloGbfs PRIVATE -mthumb -mcpu=arm7tdmi -Wall -Wextra)
target_link_libraries(helloGbfs PRIVATE tonc gbfs)
gba_target_link_runtime_library(helloGbfs rom)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    # Debug build can just fix header
    gba_target_objcopy(helloGbfs FIX_HEADER)
else()
    # Release build needs to pad the binary and output an asset-less version
    gba_target_objcopy(helloGbfs FIX_HEADER PAD 256 OUTPUT helloGbfs_noassets.gba)

    # Concatenate with helloGbfs_noassets.gba with assets.gbfs into hellGbfs.gba
    add_custom_command(TARGET helloGbfs POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E cat helloGbfs_noassets.gba assets.gbfs ">" helloGbfs.gba
    )
endif()
