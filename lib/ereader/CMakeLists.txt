#===============================================================================
#
# CMakeLists.txt for compiling libereader
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.1)
project(ereader ASM C)

add_library(ereader STATIC crt0.s ../gba-sbrk.c)

if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    set(optimization -Oz)
else()
    set(optimization -Os)
endif()

target_compile_options(ereader PRIVATE
    $<$<COMPILE_LANGUAGE:ASM>:-x assembler-with-cpp>
    $<$<COMPILE_LANGUAGE:C>:${optimization} -mabi=aapcs -march=armv4t -mcpu=arm7tdmi -mthumb -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-parameter>
)
target_link_options(ereader PRIVATE -Wl,--gc-sections)
target_include_directories(ereader PRIVATE .)

if(USE_DEVKITARM)
    target_compile_definitions(ereader PUBLIC __DEVKITARM__)
else()
    set(specs "-specs=${ARM_GNU_TOOLCHAIN}/arm-none-eabi/lib/nano.specs" "-specs=${ARM_GNU_TOOLCHAIN}/arm-none-eabi/lib/nosys.specs")
endif()

target_link_options(ereader INTERFACE
    -T ${CMAKE_CURRENT_LIST_DIR}/../ldscripts/ereader.ld
    ${specs}
    -B ${CMAKE_CURRENT_BINARY_DIR}
)
