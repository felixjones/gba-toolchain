#===============================================================================
#
# Sample libseven GBA project based on https://github.com/LunarLambda/libseven/tree/main/examples/template
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(libseven-sample C)

# Also demonstrates using minrt
gba_add_library_subdirectory(minrt seven)

add_executable(helloSeven main.c)
set_target_properties(helloSeven PROPERTIES SUFFIX ".elf")

target_compile_options(helloSeven PRIVATE -std=c99 -ffunction-sections -fdata-sections -mthumb)

target_link_libraries(helloSeven PRIVATE minrt seven)

gba_target_objcopy(helloSeven FIX_HEADER)
