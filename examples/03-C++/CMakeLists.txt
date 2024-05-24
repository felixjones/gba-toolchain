#===============================================================================
#
# C project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(03-c++-project LANGUAGES CXX VERSION 1.0.0)

find_package(librom REQUIRED)

add_executable(03-c++
        main.cpp
)

set_target_properties(03-c++ PROPERTIES CXX_STANDARD 20)

target_link_libraries(03-c++ PRIVATE
        librom
)

install_rom(03-c++)
