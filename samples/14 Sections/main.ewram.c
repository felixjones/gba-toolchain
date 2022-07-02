/*
===============================================================================

 Code in *.ewram.c executes in EWRAM

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <seven/video/prelude.h>
#include <seven/video/bg_bitmap.h>

#include "draw.h"

int main() {
    REG_DISPCNT = VIDEO_MODE_BITMAP | VIDEO_BG2_ENABLE;

    draw_line(0, 0, 239, 159, COLOR_RED);
    draw_line(0, 159, 239, 0, COLOR_GREEN);
    draw_line(0, 80, 239, 80, COLOR_BLUE);

    while (1) {}
}
