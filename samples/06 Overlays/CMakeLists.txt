#===============================================================================
#
# Sample memory overlay GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(overlay-sample C)

gba_add_library_subdirectory(rom tonc)

add_executable(helloOverlay main.c)
set_target_properties(helloOverlay PROPERTIES SUFFIX ".elf")

target_compile_options(helloOverlay PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(helloOverlay PRIVATE -Wl,--gc-sections)

target_link_libraries(helloOverlay PRIVATE rom tonc)

gba_target_objcopy(helloOverlay FIX_HEADER)
