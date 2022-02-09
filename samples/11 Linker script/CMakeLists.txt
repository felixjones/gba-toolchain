#===============================================================================
#
# Sample GBA project with custom linker script + specs
# This project demonstrates enabling C++ exceptions via newlib specs
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(linker-script-sample ASM C CXX)

gba_add_library_subdirectory(tonc)

add_executable(helloLinker crt0.s syscalls.c main.cpp)
set_target_properties(helloLinker PROPERTIES SUFFIX ".elf")

target_compile_options(helloLinker PRIVATE -mthumb -fexceptions -ffunction-sections -fdata-sections -Wall -Wextra)

# Link options for linker script and .specs file
target_link_options(helloLinker PRIVATE
    -T ${CMAKE_SOURCE_DIR}/gba-rom.ld
    -specs=${CMAKE_SOURCE_DIR}/gba-exceptions.specs
    -Wl,--gc-sections
)

target_link_libraries(helloLinker PRIVATE tonc)

gba_target_objcopy(helloLinker FIX_HEADER)
