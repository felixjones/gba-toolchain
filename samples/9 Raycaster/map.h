/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef MAP_H
#define MAP_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define MAP_SIZE 24

typedef uint8_t map_type[MAP_SIZE];

extern const map_type* map_memory;

#ifdef __cplusplus
}
#endif
#endif // define MAP_H
