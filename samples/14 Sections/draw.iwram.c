/*
===============================================================================

 Code in *.iwram.c executes in IWRAM

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "draw.h"

#include <stdlib.h>
#include <seven/video/bg_bitmap.h>

void draw_line(int x0, int y0, int x1, int y1, int color) {
    int dx = abs(x1 - x0);
    int sx = x0 < x1 ? 1 : -1;
    int dy = -abs(y1 - y0);
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    for (;;) {
        MODE3_FRAME[y0][x0] = color;
        if (x0 == x1 && y0 == y1) {
            break;
        }

        int e2 = 2 * err;
        if (e2 >= dy) {
            err += dy;
            x0 += sx;
        } else if (e2 <= dx) {
            err += dx;
            y0 += sy;
        }
    }
}
