#===============================================================================
#
# Partial implementation of sprintf optimised for GBA
#   Documentation: https://www.danposluns.com/gbadev/posprintf/instructions.html
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(TARGET posprintf)
    return()
endif()

include(FetchContent)
include(Mktemp)

mktemp(posprintfCMakeLists TMPDIR)
file(WRITE "${posprintfCMakeLists}" [=[
cmake_minimum_required(VERSION 3.25.1)
project(posprintf ASM)

add_library(posprintf STATIC
    posprintf/posprintf.S
)
target_include_directories(posprintf
    INTERFACE posprintf
)
]=])

FetchContent_Declare(posprintf
        URL "https://www.danposluns.com/gbadev/posprintf/posprintf.zip"
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${posprintfCMakeLists}" "CMakeLists.txt"
)
FetchContent_MakeAvailable(posprintf)

file(REMOVE "${posprintfCMakeLists}")
