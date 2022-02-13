/*
===============================================================================

 Constructor/initialization array caller

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

void __libc_init_array() {
    extern void (*__preinit_array_start[])() __attribute__((weak));
    extern void (*__preinit_array_end[])() __attribute__((weak));

    int count = __preinit_array_end - __preinit_array_start;
    for (int i = 0; i < count; ++i) {
        __preinit_array_start[i]();
    }

    extern void (*__init_array_start[])() __attribute__((weak));
    extern void (*__init_array_end[])() __attribute__((weak));

    count = __init_array_end - __init_array_start;
    for (int i = 0; i < count; ++i) {
        __init_array_start[i]();
    }
}
