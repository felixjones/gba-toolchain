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
    src/hw/dma.s
    src/hw/input.c
    src/hw/irq.s
    src/hw/lcd.s
    src/hw/sram.s
    src/hw/svc.s
    src/hw/timer.c
    src/util/log.c
    src/util/mem.s
    src/util/profile.s
    src/util/rand.s
    src/util/str.s
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
