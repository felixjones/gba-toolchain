#===============================================================================
#
# Sample real-time clock GBA project
#
# Copyright (C) 2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(rtc-sample C)

gba_add_library_subdirectory(rom agbabi tonc posprintf)

add_executable(helloRtc main.c)
set_target_properties(helloRtc PROPERTIES SUFFIX ".elf")

target_compile_options(helloRtc PRIVATE -mthumb -ffunction-sections -fdata-sections -Wall -Wextra)
target_link_options(helloRtc PRIVATE -Wl,--gc-sections)

target_link_libraries(helloRtc PRIVATE rom agbabi tonc posprintf)

gba_target_objcopy(helloRtc FIX_HEADER)
