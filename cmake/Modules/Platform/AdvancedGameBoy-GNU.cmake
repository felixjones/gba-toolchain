#===============================================================================
#
# Copyright (C) 2021-2024 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

if(__GBA_GNU)
    return()
endif()
set(__GBA_GNU 1)

include("${CMAKE_CURRENT_LIST_DIR}/AdvancedGameBoy-Common.cmake")

macro(__gba_compiler_gnu lang)
    __gba_compiler_common(${lang})

    # Detect if compiler is devkitARM (GNU only)
    if(NOT DEVKITARM)
        execute_process(COMMAND "${CMAKE_${lang}_COMPILER}" --version OUTPUT_VARIABLE gnuVersion OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(gnuVersion MATCHES "devkitARM")
            set(DEVKITARM 1)
        else()
            set(DEVKITARM 0)
        endif()
        unset(gnuVersion)
    endif()

    # Detect if compiler is Wonderful toolchain (GNU only)
    if(NOT WONDERFUL)
        execute_process(COMMAND "${CMAKE_${lang}_COMPILER}" --version OUTPUT_VARIABLE gnuVersion OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(gnuVersion MATCHES "Wonderful toolchain")
            set(WONDERFUL 1)
        else()
            set(WONDERFUL 0)
        endif()
        unset(gnuVersion)
    endif()

    if(DEVKITARM)
        string(APPEND CMAKE_${lang}_FLAGS_INIT " -D__DEVKITARM__")
    endif()
    if(WONDERFUL)
        string(APPEND CMAKE_${lang}_FLAGS_INIT " -D__WONDERFUL__ -D__WONDERFUL_GBA__")
    endif()
endmacro()
