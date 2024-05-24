#===============================================================================
#
# GBT-Player project
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(09-GBT-Player-project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(libgba REQUIRED)
find_package(gbt-player REQUIRED)
find_package(maxmod REQUIRED)

add_s3msplit_command(template_combined.s3m
        PSG music/template_combined_psg.s3m
        DMA maxmod/template_combined_dma.s3m
)

add_maxmod_library(soundbank
        maxmod/template_combined_dma.s3m
)

add_gbt_library(gbt
        music/template_combined_psg.s3m
)

add_executable(09-GBT-Player
        main.c
)

target_link_libraries(09-GBT-Player PRIVATE
        librom libgba
        soundbank gbt
)

install_rom(09-GBT-Player)
