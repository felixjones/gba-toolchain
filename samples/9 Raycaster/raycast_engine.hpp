/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef RAYCAST_ENGINE_HPP
#define RAYCAST_ENGINE_HPP

#include <functional>

#include "asset_manager.hpp"
#include "fixed.hpp"

class raycast_engine {
public:
    using hit_function = bool(*)(int hit, int side, fixed_type perpWallDist, fixed_type wallX);

    raycast_engine(const assets::map_type* map, const fixed_type x, const fixed_type y) noexcept : m_map { map }, m_posX { x }, m_posY { y } {}

    void operator()(fixed_type dirX, fixed_type dirY, const hit_function& onHit) const noexcept;

protected:
    const assets::map_type* m_map;
    const fixed_type m_posX;
    const fixed_type m_posY;
};

#endif // define RAYCAST_ENGINE_HPP
