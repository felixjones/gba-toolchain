#===============================================================================
#
# libgba project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(05-libgba-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(libgba REQUIRED)

add_executable(05-libgba
        main.c
)

target_link_libraries(05-libgba PRIVATE
        librom libgba
)

install_rom(05-libgba)
