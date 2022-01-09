#===============================================================================
#
# CMakeLists.txt for compiling gbfs
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(gbfs C)

if(GBA)
    # GBA library
    add_library(gbfs STATIC "libgbfs.c")

    target_include_directories(gbfs SYSTEM PUBLIC include/)
    target_compile_options(gbfs PRIVATE -mabi=aapcs -march=armv4t -mcpu=arm7tdmi -mthumb -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter)
    target_link_options(gbfs PRIVATE -Wl,--gc-sections)
else()
    # Host tools
    add_executable(gbfs "tools/gbfs.c" "tools/djbasename.c")
    add_executable(bin2s "tools/bin2s.c")
    add_executable(padbin "tools/padbin.c")

    install(TARGETS gbfs DESTINATION .)
    install(TARGETS bin2s DESTINATION .)
    install(TARGETS padbin DESTINATION .)
endif()
