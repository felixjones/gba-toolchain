#===============================================================================
#
# CMakeLists.txt for compiling posprintf
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(posprintf ASM)

add_library(posprintf STATIC
    posprintf.S
)

target_include_directories(posprintf SYSTEM PUBLIC include/)

target_compile_options(posprintf PRIVATE -x assembler-with-cpp)
