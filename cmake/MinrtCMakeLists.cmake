#===============================================================================
#
# CMakeLists.txt for compiling gba-minrt
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(gba-minrt ASM)

add_library(gba-minrt STATIC rt/crt0.s)

target_link_options(gba-minrt INTERFACE
    -mthumb
    -nostartfiles
    -specs=nano.specs -specs=nosys.specs
    -Wl,-T,${CMAKE_CURRENT_LIST_DIR}/rt/rom.ld -L${CMAKE_CURRENT_LIST_DIR}/rt
)
