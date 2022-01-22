/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef RAYCASTER_HPP
#define RAYCASTER_HPP
#ifndef __cplusplus
#error raycaster.hpp is C++ only
#endif

#include "fixed.hpp"

fixed_type raycast(fixed_type posX, fixed_type posY, fixed_type rayDirX, fixed_type rayDirY, const std::uint8_t*& outTex);

#endif // define RAYCASTER_HPP
