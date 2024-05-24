#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(__GBA_CLANG)
    return()
endif()
set(__GBA_CLANG 1)

include("${CMAKE_CURRENT_LIST_DIR}/AdvancedGameBoy-Common.cmake")

macro(__gba_compiler_clang lang)
    __gba_compiler_common(${lang})

    # Set compiler triple for Clang
    set(CMAKE_${lang}_COMPILER_TARGET "arm-none-eabi")
endmacro()
