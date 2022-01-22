/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "renderer.h"

#include "raycaster.hpp"
#include "fixed.hpp"
#include "texmapper.hpp"

#include "map.h"
#include "gba.h"

#define WIDTH 240
#define HEIGHT 160

int camera_angle = 0x4001;

static constinit fixed_type camera_x = 22.0f;
static constinit fixed_type camera_y = 11.5f;
static constinit fixed_type dir_x = 22.0f;
static constinit fixed_type dir_y = 11.5f;

static constinit const fixed_type FORWARD_SPEED = 0.1f;
static constinit const fixed_type STRAFE_SPEED = 0.1f;
static constinit const fixed_type ASPECT_RATIO = 120.0f / 150.0f;

static constinit const fixed_type IWIDTH2 = 2.0 / WIDTH;

extern "C" void camera_update(int forward, int strafe, int page) {
    dir_x = fixed_type::from_raw(__agbabi_sin(camera_angle + 0x2000) >> (29 - fixed_type::exponent));
    dir_y = fixed_type::from_raw(__agbabi_sin(camera_angle) >> (29 - fixed_type::exponent));

    if (forward || strafe) {
        auto newPosX = camera_x + dir_x * FORWARD_SPEED * forward;
        newPosX += dir_y * STRAFE_SPEED * strafe;
        if ( map_memory[(int) newPosX][(int) camera_y] == 0 ) {
            camera_x = newPosX;
        }

        auto newPosY = camera_y + dir_y * FORWARD_SPEED * forward;
        newPosY -= dir_x * STRAFE_SPEED * strafe;
        if ( map_memory[(int) camera_x][(int) newPosY] == 0 ) {
            camera_y = newPosY;
        }
    }

    auto* frameBuffer = FRAME_BUFFER + page;
    __agbabi_wordset4(frameBuffer, FRAME_BUFFER_LEN, -1);

    const auto planeX = dir_y * ASPECT_RATIO;
    const auto planeY = -dir_x * ASPECT_RATIO;

    frame_buffer = reinterpret_cast<std::uint16_t*>(frameBuffer);

    for (int x = 0; x < 240; ++x) {
        const auto cameraX = (fixed_type(x) * IWIDTH2) - 1;
        const auto rayDirX = dir_x + planeX * cameraX;
        const auto rayDirY = dir_y + planeY * cameraX;

        const std::uint8_t* texture = nullptr;
        const auto perpWallDist = raycast(camera_x, camera_y, rayDirX, rayDirY, texture);

        const auto lineHeight = (int) (HEIGHT / perpWallDist);

        render_span(x, lineHeight, texture);
    }
}
