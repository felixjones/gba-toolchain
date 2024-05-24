#===============================================================================
#
# Assembly project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(01-asm-project LANGUAGES ASM VERSION 1.0.0)

find_package(librom REQUIRED)

add_executable(01-asm
        main.s
)

target_link_libraries(01-asm PRIVATE
        librom
)

install_rom(01-asm)
