#===============================================================================
#
# CMakeLists.txt for compiling librom
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.1)
project(rom ASM C)

add_library(rom STATIC crt0.s ../gba-runtime-nosyscalls.c)
set_target_properties(rom PROPERTIES OUTPUT_NAME runtime)

target_compile_options(rom PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:-mabi=aapcs -march=armv4t -mcpu=arm7tdmi -mthumb -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter>
)
target_link_options(rom PRIVATE -Wl,--gc-sections)

set(GBA_ROM_LDSCRIPT "${CMAKE_CURRENT_LIST_DIR}/../ldscripts/rom.ld" PARENT_SCOPE)
set(GBA_ROM_SPECS "${CMAKE_CURRENT_LIST_DIR}/../gba-runtime-nano.specs" PARENT_SCOPE)
set(GBA_ROM_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" PARENT_SCOPE)
