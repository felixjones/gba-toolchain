#===============================================================================
#
# Copyright (C) 2021-2023 gba-toolchain contributors
# For conditions of distribution and use, see copyright notice in LICENSE.md
#
#===============================================================================

enable_language(ASM)

add_library(libmultiboot STATIC
    crt0.s
    multiboot.header.s
)
set_target_properties(libmultiboot PROPERTIES PREFIX "")

target_link_options(libmultiboot
    PRIVATE
        -Wl,--gc-sections
    INTERFACE
        -T "${CMAKE_CURRENT_LIST_DIR}/multiboot.ld"
        $<$<BOOL:${CMAKE_NANO}>:-specs=nano.specs>
        -specs=nosys.specs
)

execute_process(COMMAND "${CMAKE_C_COMPILER}" --version OUTPUT_VARIABLE GNU_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT GNU_VERSION MATCHES "devkitARM")
    enable_language(C)
    target_sources(libmultiboot PRIVATE syscalls.c)
endif()
