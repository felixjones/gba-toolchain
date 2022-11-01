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

add_library(gba-minrt STATIC src/crt0.s)

target_link_options(gba-minrt INTERFACE
    -mthumb
    -specs=lib/nocrt0.specs
    -specs=nano.specs -specs=nosys.specs
    -Wl,-T,${CMAKE_CURRENT_LIST_DIR}/lib/rom.ld -L${CMAKE_CURRENT_LIST_DIR}/lib
)
