/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "raycast_engine.hpp"

static constinit const auto fixed_type_max = fixed_type::from_raw(0x7fffffff);

void raycast_engine::operator()(fixed_type dirX, fixed_type dirY, const hit_function& onHit) const noexcept {
    const auto deltaDistX = !dirX ? fixed_type_max : fixed_abs(1 / dirX);
    const auto deltaDistY = !dirY ? fixed_type_max : fixed_abs(1 / dirY);

    auto mapX = static_cast<int>(m_posX);
    auto mapY = static_cast<int>(m_posY);

    int stepX;
    fixed_type sideDistX;
    if (fixed_negative(dirX)) {
        stepX = -1;
        sideDistX = fixed_frac(m_posX) * deltaDistX;
    } else {
        stepX = 1;
        sideDistX = (1 - fixed_frac(m_posX)) * deltaDistX;
    }

    int stepY;
    fixed_type sideDistY;
    if (fixed_negative(dirY))  {
        stepY = -1;
        sideDistY = fixed_frac(m_posY) * deltaDistY;
    } else {
        stepY = 1;
        sideDistY = (1 - fixed_frac(m_posY)) * deltaDistY;
    }

    int side;
    while (true) {
        if (sideDistX < sideDistY) {
            sideDistX += deltaDistX;
            mapX += stepX;
            side = 0;
        } else {
            sideDistY += deltaDistY;
            mapY += stepY;
            side = 1;
        }

        const auto hit = m_map[mapY][mapX];
        if (hit) {
            fixed_type perpWallDist, wallX;
            if (side == 0) {
                perpWallDist = sideDistX - deltaDistX;
                wallX = fixed_frac(m_posY + perpWallDist * dirY);
            } else {
                perpWallDist = sideDistY - deltaDistY;
                wallX = fixed_frac(m_posX + perpWallDist * dirX);
            }

            if (onHit(hit - 1, side, perpWallDist, wallX)) {
                break;
            }
        }
    }
}
