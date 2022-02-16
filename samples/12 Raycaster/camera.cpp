/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "camera.hpp"

#include <seven/prelude.h>

#include "asset_manager.hpp"

camera_type::camera_type(fixed_type startX, fixed_type startY, std::int32_t startAngle) noexcept : x { startX }, y { startY }, angle { startAngle } {
    dirX = fixed_type::from_raw(__agbabi_sin(angle + 0x2000) >> (29 - fixed_type::exponent));
    dirY = fixed_type::from_raw(__agbabi_sin(angle) >> (29 - fixed_type::exponent));
}

static constexpr auto camera_size = fixed_type { 1.0 / 3.0 };
static constexpr auto camera_escape_major = -camera_size;
static constexpr auto camera_escape_minor = fixed_type { 1.0 } + camera_size;

void camera_type::update() {
    const auto axisX = inputAxisX();
    if (axisX) {
        angle += axisX * turn_speed;
        dirX = fixed_type::from_raw(__agbabi_sin(angle + 0x2000) >> (29 - fixed_type::exponent));
        dirY = fixed_type::from_raw(__agbabi_sin(angle) >> (29 - fixed_type::exponent));
    }

    const auto axisY = inputAxisY();
    const auto axisLR = inputAxisLR();
    if (!axisY && !axisLR) {
        return;
    }

    const auto forward = move_speed * axisY;
    const auto strafe = strafe_speed * axisLR;

    x -= dirX * forward;
    x -= dirY * strafe;

    y -= dirY * forward;
    y += dirX * strafe;

    const auto cellX = fixed_frac(x);
    const auto cellY = fixed_frac(y);
    bool escapedWall = false;

    // Check nearest walls
    const auto tileY = static_cast<int>(y);
    if (cellX < 0.5) {
        const auto left = static_cast<int>(x - camera_size);
        if (assets::world_map[tileY][left]) {
            x = left + camera_escape_minor;
            escapedWall = true;
        }
    } else {
        const auto right = static_cast<int>(x + camera_size);
        if (assets::world_map[tileY][right]) {
            x = right + camera_escape_major;
            escapedWall = true;
        }
    }

    const auto tileX = static_cast<int>(x);
    if (cellY < 0.5) {
        const auto top = static_cast<int>(y - camera_size);
        if (assets::world_map[top][tileX]) {
            y = top + camera_escape_minor;
            escapedWall = true;
        }
    } else {
        const auto bottom = static_cast<int>(y + camera_size);
        if (assets::world_map[bottom][tileX]) {
            y = bottom + camera_escape_major;
            escapedWall = true;
        }
    }

    if (escapedWall) {
        return;
    }

    // Check nearest corners
    if (cellX < 0.5) {
        const auto left = static_cast<int>(x - camera_size);
        if (cellY < 0.5) {
            const auto top = static_cast<int>(y - camera_size);
            if (assets::world_map[top][left]) {
                if (cellX < cellY) {
                    y = top + camera_escape_minor;
                } else {
                    x = left + camera_escape_minor;
                }
            }
        } else {
            const auto bottom = static_cast<int>(y + camera_size);
            if (assets::world_map[bottom][left]) {
                if (cellX < 1 - cellY) {
                    y = bottom + camera_escape_major;
                } else {
                    x = left + camera_escape_minor;
                }
            }
        }
    } else {
        const auto right = static_cast<int>(x + camera_size);
        if (cellY < 0.5) {
            const auto top = static_cast<int>(y - camera_size);
            if (assets::world_map[top][right]) {
                if (cellY < 1 - cellX) {
                    x = right + camera_escape_major;
                } else {
                    y = top + camera_escape_minor;
                }
            }
        } else {
            const auto bottom = static_cast<int>(y + camera_size);
            if (assets::world_map[bottom][right]) {
                if (cellY < cellX) {
                    y = bottom + camera_escape_major;
                } else {
                    x = right + camera_escape_major;
                }
            }
        }
    }
}
