#===============================================================================
#
# CMakeLists.txt for compiling libseven
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(seven C ASM)

add_library(seven STATIC
    src/svc.s
    src/irq.s
    src/input.c
    src/timer.c
    src/dma.s
    src/log.c
    src/mem.s
    src/str.s
    src/lcd.s
    src/rand.s
    src/profile.s
    src/sram.s
)

target_include_directories(seven SYSTEM PUBLIC include/)
target_include_directories(seven PRIVATE src/)

if(NOT USE_CLANG)
    set(flagInterwork -mthumb-interwork)
endif()

target_compile_options(seven PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:-Os -g -ffunction-sections -fdata-sections -ffreestanding -std=c99 -Wall -Wpedantic -mcpu=arm7tdmi -mthumb ${flagInterwork}>
)

add_library(libseven ALIAS seven)
