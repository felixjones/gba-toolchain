#===============================================================================
#
# C project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(02-c-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)

add_executable(02-c
        main.c
)

set_target_properties(02-c PROPERTIES C_STANDARD 17)

target_link_libraries(02-c PRIVATE
        librom
)

install_rom(02-c)
