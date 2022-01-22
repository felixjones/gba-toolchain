/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "texmapper.hpp"

#include "fixed.hpp"
#include "texture.h"

#define WIDTH 240
#define HEIGHT 160

static constinit const fixed_type FIXED_TEXTURE_SIZE = TEXTURE_SIZE;

std::uint16_t* frame_buffer = nullptr;

static std::uint16_t column_buffer[HEIGHT] = { 0xffff };
static int column_start = 0;
static int column_end = 0;

void render_span(int x, int lineHeight, const std::uint8_t* texture) {
    const auto col = x & 1;

    auto drawStart = -lineHeight / 2 + (HEIGHT / 2);
    if (drawStart < 0) {
        drawStart = 0;
    }
    auto drawEnd = lineHeight / 2 + (HEIGHT / 2);
    if (drawEnd > HEIGHT) {
        drawEnd = HEIGHT;
    }

    const auto step = FIXED_TEXTURE_SIZE / lineHeight;

    auto texPos = (drawStart - (HEIGHT / 2) + (lineHeight / 2)) * step;

    for (int y = drawStart; y < drawEnd; ++y) {
        int texY = (int) texPos;
        texPos += step;

        uint8_t color = texture[texY];
        if (col) {
            column_buffer[y] &= 0xff;
            column_buffer[y] |= (color << 8);
        } else {
            column_buffer[y] = 0xff00 | color;
        }

        if (col) {
            frame_buffer[((y * WIDTH) + x) / 2] = column_buffer[y];
            column_buffer[y] = 0xffff;
        }
    }

    if (col) {
        for (int y = column_start; y < drawStart; ++y) {
            frame_buffer[((y * WIDTH) + x) / 2] = column_buffer[y];
            column_buffer[y] = 0xffff;
        }
        for (int y = drawEnd; y < column_end; ++y) {
            frame_buffer[((y * WIDTH) + x) / 2] = column_buffer[y];
            column_buffer[y] = 0xffff;
        }
    } else {
        column_start = drawStart;
        column_end = drawEnd;
    }
}
