#===============================================================================
#
# Sample GBA project based on https://www.coranac.com/tonc/text/first.htm
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

# Create project titled "first"
project(first C)

# Add librom
gba_add_library_subdirectory(rom)

# Create executable target "first" with the source code "first.c"
add_executable(first first.c)
set_target_properties(first PROPERTIES SUFFIX ".elf") # Output with .elf extension

# -mthumb compiles thumb code
# -mcpu=arm7tdmi tunes the code for the GBA's CPU
# -Wall enables all warnings
target_compile_options(first PRIVATE -mthumb -Wall)

# Add additional flags to IWRAM sources
gba_target_sources_compile_options(first IWRAM -g0 -Os -marm)

# Link with librom
gba_target_link_runtime_library(first rom)

# Objcopy the target's output into a .gba binary and fix the header
gba_target_objcopy(first FIX_HEADER)
