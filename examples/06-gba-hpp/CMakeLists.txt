#===============================================================================
#
# gba-hpp project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(06-gba-hpp-project LANGUAGES CXX VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(gba-hpp REQUIRED)

add_executable(06-gba-hpp
        main.cpp
)

target_link_libraries(06-gba-hpp PRIVATE
        librom gba-hpp
)

install_rom(06-gba-hpp)
