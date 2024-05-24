#===============================================================================
#
# Posprintf project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(11-posprintf-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(posprintf REQUIRED)

add_executable(11-posprintf
        main.c
)

target_link_libraries(11-posprintf PRIVATE
        librom tonclib posprintf
)

install_rom(11-posprintf)
