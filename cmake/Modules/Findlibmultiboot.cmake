#===============================================================================
#
# GBA Multiboot runtime library
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

add_subdirectory("${CMAKE_SYSTEM_PREFIX_PATH}/lib/multiboot" "${CMAKE_CURRENT_BINARY_DIR}/lib/multiboot" EXCLUDE_FROM_ALL)
