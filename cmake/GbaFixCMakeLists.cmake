#===============================================================================
#
# CMakeLists.txt for compiling gbafix.c
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(gbafix C)

add_executable(gbafix gbafix.c)

install(TARGETS gbafix DESTINATION .)
