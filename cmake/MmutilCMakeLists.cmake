#===============================================================================
#
# CMakeLists.txt for compiling mmutil
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(mmutil C)

add_executable(mmutil
    source/adpcm.c
    source/files.c source/gba.c
    source/it.c source/kiwi.c source/main.c source/mas.c
    source/mod.c source/msl.c source/nds.c
    source/s3m.c source/samplefix.c
    source/simple.c source/upload.c
    source/wav.c source/xm.c
)

target_include_directories(mmutil PRIVATE source)
target_compile_definitions(mmutil PRIVATE PACKAGE_VERSION="1.9.1")
if (NOT MSVC)
    target_link_libraries(mmutil PRIVATE m)
endif()

install(TARGETS mmutil DESTINATION .)
