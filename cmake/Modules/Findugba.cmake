#===============================================================================
#
# Universal GBA Library
#   GitHub: https://github.com/AntonioND/libugba.git
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

include(FetchContent)
include(Mktemp)

mktemp(ugbaCMakeLists TMPDIR)
file(WRITE "${ugbaCMakeLists}" [=[
if(NOT GBA)
    message(FATAL_ERROR "This CMakeLists.txt patch is intended for use with gba-toolchain")
endif()

cmake_minimum_required(VERSION 3.25.1)
project(ugba ASM C)

file(GLOB sources CONFIGURE_DEPENDS "source/*.c" "source/graphics/*.c" "source/gba/*.c" "source/gba/*.s")

add_library(ugba STATIC ${sources})
target_include_directories(ugba PUBLIC include)
]=])

FetchContent_Declare(ugba
        GIT_REPOSITORY "https://github.com/AntonioND/libugba.git"
        GIT_TAG "master"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${ugbaCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(ugba)

file(REMOVE "${ugbaCMakeLists}")
