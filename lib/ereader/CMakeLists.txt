#===============================================================================
#
# CMakeLists.txt for compiling libereader
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.1)
project(ereader ASM C)

add_library(ereader STATIC crt0.s ../gba-runtime-nosyscalls.c ../gba-runtime-init_array.c ../gba-runtime-fini_array.c)
set_target_properties(ereader PROPERTIES OUTPUT_NAME runtime)

if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    set(optimization -Oz)
else()
    set(optimization -Os)
endif()

target_compile_options(ereader PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:${optimization} -mabi=aapcs -march=armv4t -mcpu=arm7tdmi -mthumb -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter>
)
target_link_options(ereader PRIVATE -Wl,--gc-sections)

set(GBA_EREADER_LDSCRIPT "${CMAKE_CURRENT_LIST_DIR}/../ldscripts/ereader.ld" PARENT_SCOPE)
set(GBA_EREADER_SPECS "${CMAKE_CURRENT_LIST_DIR}/../gba-runtime-nano.specs" PARENT_SCOPE)
set(GBA_EREADER_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}" PARENT_SCOPE)
