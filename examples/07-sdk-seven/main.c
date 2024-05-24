/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <seven/prelude.h>
#include <seven/video/bg_bitmap.h>

#include <util/log.h>

int main() {
    logInit();
    logSetMaxLevel(LOG_INFO);
    logOutput(LOG_INFO, "Hello, sdk-seven!");

    REG_DISPCNT = DISPLAY_MODE(3) | DISPLAY_BG2_ENABLE;

    MODE3_FRAME[80][120] = 0x001F;
    MODE3_FRAME[80][136] = 0x03E0;
    MODE3_FRAME[96][120] = 0x7C00;

    biosHalt();

    __builtin_unreachable();
}
