/*
===============================================================================

 Destructor/finalization array caller

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

void __libc_fini_array() {
    extern void (*__fini_array_start[])() __attribute__((weak));
    extern void (*__fini_array_end[])() __attribute__((weak));

    const int count = __fini_array_end - __fini_array_start;
    for (int i = 0; i < count; ++i) {
        __fini_array_start[i]();
    }
}
