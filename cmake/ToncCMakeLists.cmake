#===============================================================================
#
# CMakeLists.txt for compiling Tonclib
#
# Copyright (C) 2021-2022 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.0)

project(tonc C ASM)

# This is not the recommended way to collect sources
file(GLOB sources "asm/*.s" "src/*.c" "src/*.s" "src/font/*.s" "src/tte/*.c" "src/tte/*.s" "src/pre1.3/*.c" "src/pre1.3/*.s")

# Remove tt_iohook.c which isn't compatible right now
get_filename_component(iohook "${CMAKE_CURRENT_SOURCE_DIR}/src/tte/tte_iohook.c" ABSOLUTE)
list(REMOVE_ITEM sources "${iohook}")

add_library(tonc STATIC ${sources})
target_include_directories(tonc SYSTEM PUBLIC include/)

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter -Wno-char-subscripts -Wno-sign-compare -Wno-implicit-fallthrough -Wno-type-limits")
