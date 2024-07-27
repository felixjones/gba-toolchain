#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(syscalls C)

if(NOT TARGET syscalls-stub)
    add_library(syscalls-stub STATIC
            stub/syscalls.c
    )
    # Keep the stub symbols
    target_link_options(syscalls-stub INTERFACE
            "-Wl,--undefined=_getpid"
            "-Wl,--undefined=_kill"
    )
endif()
