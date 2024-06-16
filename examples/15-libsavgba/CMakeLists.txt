#===============================================================================
#
# Tonc project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(15-libsavgba-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(libsavgba REQUIRED)

add_executable(15-libsavgba
        main.c
)

target_link_libraries(15-libsavgba PRIVATE
        librom tonclib libsavgba
)

install_rom(15-libsavgba)
