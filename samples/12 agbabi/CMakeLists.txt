#===============================================================================
#
# Sample agbabi GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(agbabi-sample C)

gba_add_library_subdirectory(rom agbabi tonc)

add_executable(helloAgbabi main.c)
set_target_properties(helloAgbabi PROPERTIES SUFFIX ".elf")

target_compile_options(helloAgbabi PRIVATE -std=c99 -ffunction-sections -fdata-sections -mthumb)

target_link_libraries(helloAgbabi PRIVATE rom agbabi tonc)

gba_target_objcopy(helloAgbabi FIX_HEADER)
