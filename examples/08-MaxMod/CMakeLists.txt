#===============================================================================
#
# Maxmod project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(08-MaxMod-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(libgba REQUIRED)
find_package(maxmod REQUIRED)

add_maxmod_library(soundbank
        maxmod_data/Ambulance.wav
        maxmod_data/Boom.wav
        maxmod_data/FlatOutLies.mod
)

add_executable(08-MaxMod
        main.c
)

target_link_libraries(08-MaxMod PRIVATE
        librom libgba
        soundbank
)

install_rom(08-MaxMod)
