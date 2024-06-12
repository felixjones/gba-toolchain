#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(libmultiboot ASM)

if(TARGET libmultiboot)
    return()
endif()

add_library(libmultiboot STATIC
        crt0.s
        multiboot.header.s
)
set_target_properties(libmultiboot PROPERTIES PREFIX "")

target_link_options(libmultiboot INTERFACE
        -T "${CMAKE_CURRENT_LIST_DIR}/multiboot.ld"
        $<$<BOOL:${NEWLIB_NANO}>:-specs=nano.specs>
        $<IF:$<BOOL:${PICOLIBC}>,-specs=picolibc.specs,-specs=nosys.specs>
)
