/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <cstdint>

[[noreturn]]
int main() {
    *reinterpret_cast<volatile std::uint16_t*>(0x04000000) = 0x0403;

    reinterpret_cast<volatile std::uint16_t*>(0x06000000)[120 + 80 * 240] = 0x001F;
    reinterpret_cast<volatile std::uint16_t*>(0x06000000)[136 + 80 * 240] = 0x03E0;
    reinterpret_cast<volatile std::uint16_t*>(0x06000000)[120 + 96 * 240] = 0x7C00;

    asm("swi 0x2 << ((1f - . == 4) * -16); 1:"); // SWI 0x02 HALT
    __builtin_unreachable();
}
