#===============================================================================
#
# Sample Tonclib GBA project based on https://github.com/exelotl/libtonc-template
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(gba-hpp CXX)

gba_add_library_subdirectory(rom gba-hpp)

add_executable(helloGbaHpp main.cpp)
set_target_properties(helloGbaHpp PROPERTIES SUFFIX ".elf")

target_compile_options(helloGbaHpp PRIVATE -mthumb -Wall -Wextra)

target_link_libraries(helloGbaHpp PRIVATE rom gba-hpp)

gba_target_objcopy(helloGbaHpp FIX_HEADER)
