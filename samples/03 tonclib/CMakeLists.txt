#===============================================================================
#
# Sample Tonclib GBA project based on https://github.com/exelotl/libtonc-template
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(libtonc-template C)

gba_add_library_subdirectory(rom tonc)

add_executable(helloTonc main.c)
set_target_properties(helloTonc PROPERTIES SUFFIX ".elf")

target_compile_options(helloTonc PRIVATE -mthumb -Wall)

target_link_libraries(helloTonc PRIVATE tonc)
gba_target_link_runtime_library(helloTonc rom)

gba_target_objcopy(helloTonc FIX_HEADER)
