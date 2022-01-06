#===============================================================================
#
# Sample e-reader GBA project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(sample-ereader C)

gba_add_library_subdirectory(ereader tonc)

add_executable(helloDotCode main.c)
set_target_properties(helloDotCode PROPERTIES SUFFIX ".elf")

# Really we want MinSizeRel always
if(USE_CLANG)
    set(optimization -Oz)
else()
    set(optimization -Os)
endif()
target_compile_options(helloDotCode PRIVATE -Wall -mcpu=arm7tdmi -mthumb)
target_compile_options(tonc PRIVATE ${optimization})

target_link_libraries(helloDotCode PRIVATE tonc)
gba_target_link_runtime_library(helloDotCode ereader)

gba_target_objcopy(helloDotCode ARCHIVE_DOTCODE NAME "Hello, e-reader!")
