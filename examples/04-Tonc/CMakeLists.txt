#===============================================================================
#
# Tonc project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(04-tonc-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)

add_executable(04-tonc
        main.c
)

target_link_libraries(04-tonc PRIVATE
        librom tonclib
)

install_rom(04-tonc)
