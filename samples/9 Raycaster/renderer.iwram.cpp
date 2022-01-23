/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "renderer.hpp"

#include <seven/video/mode4.h>
#include <agbabi.h>

#include "asset_manager.hpp"
#include "raycast_engine.hpp"

void renderer::init() {}

static constexpr auto half_width = fixed_type(MODE4_WIDTH / 2.0);
static constexpr auto reciprocal_width = fixed_type(2.0 / MODE4_WIDTH);

static std::uint8_t* frame_buffer;
static int screen_x;
static fixed_type ray_dirX;
static fixed_type ray_dirY;

void renderer::draw_world(std::uint8_t* frameBuffer, const camera_type& camera) {
    __agbabi_wordset4(frameBuffer, 0xA000, -1);
    frame_buffer = frameBuffer;

    const auto planeX = camera.dir_y() * aspect_ratio;
    const auto planeY = -camera.dir_x() * aspect_ratio;

    const auto raycast = raycast_engine { assets::world_map, camera.x, camera.y };
    for (screen_x = 0; screen_x < MODE4_WIDTH; screen_x += 2) {
        const auto cameraX = (screen_x - half_width) * reciprocal_width;
        ray_dirX = camera.dir_x() + planeX * cameraX;
        ray_dirY = camera.dir_y() + planeY * cameraX;

        raycast(ray_dirX, ray_dirY, [](auto hit, auto side, auto perpWallDist, auto wallX) {
            const auto lineHeight = static_cast<int>(MODE4_HEIGHT / perpWallDist);

            auto drawStart = -lineHeight / 2 + (MODE4_HEIGHT / 2);
            if (drawStart < 0) {
                drawStart = 0;
            }

            auto drawEnd = lineHeight / 2 + (MODE4_HEIGHT / 2);
            if (drawEnd > MODE4_HEIGHT) {
                drawEnd = MODE4_HEIGHT;
            }

            auto texX = static_cast<int>(wallX * assets::texture_size);
            if ((side == 0 && ray_dirX > 0) || (side == 1 && ray_dirY < 0)) {
                texX = assets::texture_size - texX - 1;
            }

            const auto& texture = assets::texture_array[hit][side][texX];
            const auto step = fixed_type(assets::texture_size) / lineHeight;

            auto texPos = (drawStart - (MODE4_HEIGHT / 2) + (lineHeight / 2)) * step;
            for (int y = drawStart; y < drawEnd; ++y) {
                frame_buffer[(y * MODE4_WIDTH) + screen_x] = texture[static_cast<int>(texPos)];
                texPos += step;
            }

            return true;
        });
    }
}
