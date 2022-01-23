/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef RENDERER_HPP
#define RENDERER_HPP

#include "camera.hpp"
#include "fixed.hpp"

namespace renderer {

    constexpr auto aspect_ratio = fixed_type { 120.0 / 150.0 };

    void init();
    void draw_world(std::uint8_t* frameBuffer, const camera_type& camera);

} // renderer

#endif // define RENDERER_HPP
