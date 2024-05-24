/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <stdint.h>

int __attribute__((noreturn)) main() {
    *(volatile uint16_t*) 0x04000000 = 0x0403;

    ((volatile uint16_t*) 0x06000000)[120 + 80 * 240] = 0x001F;
    ((volatile uint16_t*) 0x06000000)[136 + 80 * 240] = 0x03E0;
    ((volatile uint16_t*) 0x06000000)[120 + 96 * 240] = 0x7C00;

    asm("swi 0x2 << ((1f - . == 4) * -16); 1:"); // SWI 0x02 HALT
    __builtin_unreachable();
}
