#===============================================================================
#
# Sample coroutine GBA project
#
# Copyright (C) 2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(coroutine-sample C)

gba_add_library_subdirectory(rom agbabi tonc posprintf)

add_executable(helloCoro main.c)
set_target_properties(helloCoro PROPERTIES SUFFIX ".elf")

target_compile_options(helloCoro PRIVATE -O0 -g -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(helloCoro PRIVATE -Wl,--gc-sections)

target_link_libraries(helloCoro PRIVATE agbabi tonc posprintf)
gba_target_link_runtime_library(helloCoro rom)

gba_target_objcopy(helloCoro FIX_HEADER)
