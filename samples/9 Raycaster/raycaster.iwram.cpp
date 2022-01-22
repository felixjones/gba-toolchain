/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "raycaster.hpp"
#include "map.h"
#include "texture.h"

static constinit const fixed_type INFINITY = fixed_type::from_raw(0x7fffffff);

fixed_type raycast(const fixed_type posX, const fixed_type posY, const fixed_type rayDirX, const fixed_type rayDirY, const std::uint8_t*& outTex) {
    const auto deltaDistX = !rayDirX ? INFINITY : fixed_abs(1 / rayDirX);
    const auto deltaDistY = !rayDirY ? INFINITY : fixed_abs(1 / rayDirY);

    auto mapX = (int) posX;
    auto mapY = (int) posY;

    int stepX;
    fixed_type sideDistX;
    if (rayDirX < 0) {
        stepX = -1;
        sideDistX = (posX - mapX) * deltaDistX;
    } else {
        stepX = 1;
        sideDistX = (mapX + 1 - posX) * deltaDistX;
    }

    int stepY;
    fixed_type sideDistY;
    if (rayDirY < 0)  {
        stepY = -1;
        sideDistY = (posY - mapY) * deltaDistY;
    } else {
        stepY = 1;
        sideDistY = (mapY + 1 - posY) * deltaDistY;
    }

    int side;
    int hit = 0;
    while (!hit) {
        if (sideDistX < sideDistY) {
            sideDistX += deltaDistX;
            mapX += stepX;
            side = 0;
        } else {
            sideDistY += deltaDistY;
            mapY += stepY;
            side = 1;
        }
        hit = map_memory[mapX][mapY];
    }

    fixed_type perpWallDist;
    if (side == 0) {
        perpWallDist = (sideDistX - deltaDistX);
    } else {
        perpWallDist = (sideDistY - deltaDistY);
    }

    fixed_type wallX;
    if (side == 0) {
        wallX = posY + perpWallDist * rayDirY;
    } else {
        wallX = posX + perpWallDist * rayDirX;
    }
    wallX -= fixed_floor(wallX);

    auto texX = (int) (wallX * TEXTURE_SIZE);
    if ((side == 0 && rayDirX > 0) || (side == 1 && rayDirY < 0)) {
        texX = TEXTURE_SIZE - texX - 1;
    }

    outTex = &texture_memory[hit - 1][side][texX][0];
    return perpWallDist;
}
