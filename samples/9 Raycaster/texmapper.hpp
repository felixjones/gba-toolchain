/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef TEXMAPPER_HPP
#define TEXMAPPER_HPP
#ifndef __cplusplus
#error texmapper.hpp is C++ only
#endif

#include <cstdint>

extern std::uint16_t* frame_buffer;

void render_span(int x, int lineHeight, const std::uint8_t* texture);

#endif // define TEXMAPPER_HPP
