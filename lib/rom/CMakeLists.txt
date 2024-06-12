#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(librom ASM)

if(TARGET librom)
    return()
endif()

add_library(librom STATIC
        crt0.s
        rom.header.s
)
set_target_properties(librom PROPERTIES PREFIX "")

target_link_options(librom INTERFACE
        -T "${CMAKE_CURRENT_SOURCE_DIR}/rom.ld"
        $<$<BOOL:${NEWLIB_NANO}>:-specs=nano.specs>
        $<IF:$<BOOL:${PICOLIBC}>,-specs=picolibc.specs,-specs=nosys.specs>
)
