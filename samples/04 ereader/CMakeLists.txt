#===============================================================================
#
# Sample e-reader GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(sample-ereader C)

gba_add_library_subdirectory(ereader tonc)

add_executable(helloDotCode main.c)
set_target_properties(helloDotCode PROPERTIES SUFFIX ".elf")

target_compile_options(helloDotCode PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(helloDotCode PRIVATE -Wl,--gc-sections)

target_link_libraries(helloDotCode PRIVATE ereader tonc)

gba_target_objcopy(helloDotCode ARCHIVE_DOTCODE NAME "Hello, e-reader!")
