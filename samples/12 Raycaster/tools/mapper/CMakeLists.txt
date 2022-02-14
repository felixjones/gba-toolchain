#===============================================================================
#
# Raycaster host tool
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.20)

project(mapper C)

if(GBA)
    message(FATAL_ERROR "This is NOT a GBA project")
endif()

add_executable(mapper mapper.c)

install(TARGETS mapper DESTINATION .)
