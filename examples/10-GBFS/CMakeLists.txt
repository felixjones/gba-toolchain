#===============================================================================
#
# GBFS project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(10-GBFS-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(gbfs REQUIRED)

add_gbfs_library(assets hello.txt)

add_executable(10-GBFS
        main.c
)

target_link_libraries(10-GBFS PRIVATE
        librom tonclib
        assets
)

install_rom(10-GBFS)
