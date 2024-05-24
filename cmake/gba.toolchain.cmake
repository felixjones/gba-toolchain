#===============================================================================
#
# CMake toolchain file
#   Use with `--toolchain=/path/to/gba.toolchain.cmake`
#   Arm compiler tools are required
#   Using this toolchain file will enable several CMake modules within `/Modules`
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

cmake_minimum_required(VERSION 3.25.1)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/Modules")

set(CMAKE_SYSTEM_NAME "AdvancedGameBoy")
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "armv4t")
set(CMAKE_CROSSCOMPILING TRUE)

if(CMAKE_TOOLCHAIN_FILE) # Workaround https://gitlab.kitware.com/cmake/cmake/-/issues/17261
endif()

# Set system prefix path
get_filename_component(CMAKE_SYSTEM_PREFIX_PATH "${CMAKE_CURRENT_LIST_DIR}" DIRECTORY CACHE)
