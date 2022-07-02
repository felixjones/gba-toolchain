#===============================================================================
#
# Sample GBA sources-sections project
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.18)

project(sections-sample C)

gba_add_library_subdirectory(rom seven)

add_executable(helloSections main.ewram.c draw.iwram.c)
set_target_properties(helloSections PROPERTIES SUFFIX ".elf")

target_compile_options(helloSections PRIVATE -ffunction-sections -fdata-sections -mthumb)
target_link_options(helloSections PRIVATE -Wl,--gc-sections)

target_link_libraries(helloSections PRIVATE rom seven)

if(CMAKE_BUILD_TYPE STREQUAL Debug)
    # Compile IWRAM and EWRAM sources with debug flags
    gba_target_sources_compile_options(helloSections
        IWRAM -g -Og -marm
        EWRAM -g -Og -mthumb
    )
else()
    # Compile IWRAM and EWRAM sources with custom options
    gba_target_sources_compile_options(helloSections
        IWRAM -g0 -Os -marm
        EWRAM -g0 -O3 -mthumb
    )
endif()

gba_target_objcopy(helloSections FIX_HEADER)
