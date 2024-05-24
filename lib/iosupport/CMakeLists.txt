#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(iosupport C)

if(TARGET iosupport)
    return()
endif()

add_library(iosupport STATIC
        source/sys/iosupport.c
)
target_include_directories(iosupport PUBLIC include)
