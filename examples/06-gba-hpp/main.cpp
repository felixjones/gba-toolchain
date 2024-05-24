/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <gba/gba.hpp>

[[noreturn]]
int main() {
    using namespace gba;

    mmio::DISPCNT = {
        .video_mode = 3,
        .show_bg2 = true
    };

    mmio::VIDEO3_VRAM[80][120] = 0x001F;
    mmio::VIDEO3_VRAM[80][136] = 0x03E0;
    mmio::VIDEO3_VRAM[96][120] = 0x7C00;

    bios::Halt();

    __builtin_unreachable();
}
