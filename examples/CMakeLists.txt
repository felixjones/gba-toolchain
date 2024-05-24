#===============================================================================
#
# Example CMake projects
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)
project(gba-toolchain-examples)

file(GLOB exampleDirs LIST_DIRECTORIES TRUE "[0-9][0-9]*")
foreach(exampleDir ${exampleDirs})
    add_subdirectory("${exampleDir}")
endforeach()
