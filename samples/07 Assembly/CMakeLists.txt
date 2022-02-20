#===============================================================================
#
# Sample GBA Assembly language project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(sample-assembly ASM)

gba_add_library_subdirectory(rom)

add_executable(helloAsm main.s)
set_target_properties(helloAsm PROPERTIES SUFFIX ".elf")

target_link_libraries(helloAsm PRIVATE rom)

gba_target_objcopy(helloAsm FIX_HEADER)
