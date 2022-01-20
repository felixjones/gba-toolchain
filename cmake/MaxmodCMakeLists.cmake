#===============================================================================
#
# CMakeLists.txt for compiling Maxmod
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(maxmod ASM)

add_library(maxmod STATIC
    source/mm_effect.s
    source/mm_main.s
    source/mm_mas.s
    source/mm_mas_arm.s
    source_gba/mm_init_default.s
    source_gba/mm_mixer_gba.s
)
set_target_properties(maxmod PROPERTIES OUTPUT_NAME mm)

target_include_directories(maxmod SYSTEM PUBLIC include/)
target_include_directories(maxmod PRIVATE asm_include/)
target_compile_definitions(maxmod PRIVATE SYS_GBA USE_IWRAM)
target_compile_options(maxmod PRIVATE -x assembler-with-cpp)

add_library(mm ALIAS maxmod)
