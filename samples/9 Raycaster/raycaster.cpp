/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "gba.h"
#include "map.h"
#include "texture.h"

#include <agbabi.h>
#include <cstdint>
#include <concepts>

#define WIDTH 240
#define HEIGHT 160

#define Q 16

struct fixed_type {
    using data_type = std::int32_t;

    constexpr fixed_type() noexcept : data {} {}

    constexpr fixed_type(std::integral auto x) noexcept : data { x << Q } {}

    consteval fixed_type(std::floating_point auto x) noexcept : data { static_cast<data_type>(x * (1 << Q)) } {}

    static constexpr auto from_raw(const data_type x) noexcept  {
        fixed_type y;
        y.data = x;
        return y;
    }

    explicit operator float() const noexcept {
        return static_cast<float>(data) / (1 << Q);
    }

    constexpr explicit operator int() const noexcept {
        return data >> Q;
    }

    constexpr auto operator +(std::integral auto x) const noexcept {
        return from_raw(data + (x << Q));
    }

    constexpr auto operator +(const fixed_type o) const noexcept {
        return from_raw(data + o.data);
    }

    constexpr auto& operator +=(const fixed_type o) noexcept {
        data += o.data;
        return *this;
    }

    constexpr auto& operator -=(const fixed_type o) noexcept {
        data -= o.data;
        return *this;
    }

    constexpr auto operator -(std::integral auto x) const noexcept {
        return from_raw(data - (x << Q));
    }

    constexpr auto operator -(const fixed_type o) const noexcept {
        return from_raw(data - o.data);
    }

    constexpr auto& operator -=(std::integral auto x) noexcept {
        data -= (x << Q);
        return *this;
    }

    constexpr auto operator *(std::integral auto x) const noexcept {
        return from_raw(static_cast<std::int64_t>(data) * x);
    }

    constexpr auto operator *(const fixed_type o) const noexcept {
        return from_raw(static_cast<data_type>((static_cast<std::int64_t>(data) * o.data) >> Q));
    }

    constexpr auto operator /(const fixed_type o) const noexcept {
        const auto dataLL = static_cast<std::int64_t>(data) << Q;
        if (std::is_constant_evaluated()) {
            return from_raw(static_cast<data_type>(dataLL / o.data));
        }
        return from_raw(static_cast<data_type>(__agbabi_uluidiv(dataLL, o.data)));
    }

    constexpr auto operator -() const noexcept {
        return from_raw(-data);
    }

    constexpr auto operator <<(std::integral auto x) const noexcept {
        return from_raw(data << x);
    }

    constexpr auto operator <(std::integral auto x) const noexcept {
        return (data >> Q) < x;
    }

    constexpr auto operator >(std::integral auto x) const noexcept {
        return data > (x << Q);
    }

    constexpr auto operator !() const noexcept {
        return data == 0;
    }

    constexpr auto operator <(const fixed_type o) const noexcept {
        return data < o.data;
    }

    data_type data;
};

constexpr auto operator +(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw((x << Q) + y.data);
}

constexpr auto operator -(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw((x << Q) - y.data);
}

constexpr auto operator *(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw(x * y.data);
}

constexpr auto operator /(std::integral auto x, const fixed_type y) noexcept {
    const auto dataLL = static_cast<std::int64_t>(x) << (Q * 2);
    if (std::is_signed_v<decltype(x)> || std::is_constant_evaluated()) {
        return fixed_type::from_raw(static_cast<fixed_type::data_type>(dataLL / y.data));
    }
    return fixed_type::from_raw(static_cast<fixed_type::data_type>(__agbabi_uluidiv(dataLL, y.data)));
}

[[gnu::naked]]
std::int32_t bios_sqrt([[maybe_unused]] std::int32_t x) {
    __asm__(
#if defined( __thumb__ )
        "swi\t%[Swi]\n\t"
#elif defined( __arm__ )
        "swi\t%[Swi] << 16\n\t"
#endif
        "bx\tlr"
        :: [Swi]"i"( 0x8 )
    );
}

static fixed_type fixed_floor(const fixed_type x) noexcept {
    return fixed_type::from_raw(x.data & static_cast<fixed_type::data_type>(0xffffffffu << Q));
}

static fixed_type fixed_abs(const fixed_type x) noexcept {
    return fixed_type::from_raw(x.data < 0 ? -x.data : x.data);
}

extern "C" {
    int camera_angle = 0x4000;
    int move_z;
    int move_x;
}

static constinit fixed_type posX = 22.0f;
static constinit fixed_type posY = 11.5f;

static const fixed_type ASPECT_RATIO = 120.0f / 160.0f;
static const fixed_type MOVE_SPEED = 0.1f;

extern "C" void raycast(int page) {
    const auto dirX = fixed_type::from_raw(__agbabi_sin(camera_angle + 0x2000) >> (29 - Q));
    const auto dirY = fixed_type::from_raw(__agbabi_sin(camera_angle) >> (29 - Q));

    if (move_z || move_x) {
        posX += dirX * MOVE_SPEED * move_z;
        posY += dirY * MOVE_SPEED * move_z;
        posY -= dirX * MOVE_SPEED * move_x;
        posX += dirY * MOVE_SPEED * move_x;
    }

    const auto planeX = dirY * ASPECT_RATIO;
    const auto planeY = -dirX * ASPECT_RATIO;

    __agbabi_wordset4(FRAME_BUFFER + page, FRAME_BUFFER_LEN, 0);

    for (int x = 0; x < WIDTH; x += 2) {
        fixed_type cameraX = (fixed_type(x) / (WIDTH / 2)) - 1;
        fixed_type rayDirX = dirX + planeX * cameraX;
        fixed_type rayDirY = dirY + planeY * cameraX;

        fixed_type deltaDistX = !rayDirX ? fixed_type::from_raw(0x7fffffff) : fixed_abs(1 / rayDirX);
        fixed_type deltaDistY = !rayDirY ? fixed_type::from_raw(0x7fffffff) : fixed_abs(1 / rayDirY);

        int mapX = (int) posX;
        int mapY = (int) posY;

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

        bool hit = false;
        int side;
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

        int lineHeight = (int) (HEIGHT / perpWallDist);

        int drawStart = -lineHeight / 2 + HEIGHT / 2;
        if (drawStart < 0) {
            drawStart = 0;
        }
        int drawEnd = lineHeight / 2 + HEIGHT / 2;
        if (drawEnd >= HEIGHT) {
            drawEnd = HEIGHT - 1;
        }

        int texNum = map_memory[mapX][mapY] - 1;

        fixed_type wallX;
        if (side == 0) {
            wallX = posY + perpWallDist * rayDirY;
        } else {
            wallX = posX + perpWallDist * rayDirX;
        }
        wallX -= fixed_floor(wallX);

        int texX = (int) (wallX * TEXTURE_SIZE);
        if(side == 0 && rayDirX > 0) texX = TEXTURE_SIZE - texX - 1;
        if(side == 1 && rayDirY < 0) texX = TEXTURE_SIZE - texX - 1;

        fixed_type step = TEXTURE_SIZE / fixed_type { lineHeight };

        fixed_type texPos = (drawStart - HEIGHT / 2 + lineHeight / 2) * step;
        for (int y = drawStart; y < drawEnd; ++y) {
            int texY = (int) texPos & (TEXTURE_SIZE - 1);
            texPos += step;

            uint8_t color = texture_memory[texNum][side][texX][texY];

            (FRAME_BUFFER + page)[(y * WIDTH) + x] = color;
        }
    }
}
