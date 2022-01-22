/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef TEXTURE_H
#define TEXTURE_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define TEXTURE_SIZE 64

typedef uint8_t texture_row_type[TEXTURE_SIZE];
typedef texture_row_type texture_column_type[TEXTURE_SIZE];
typedef texture_column_type texture_type[2];

extern const texture_type* texture_memory;

#ifdef __cplusplus
}
#endif
#endif // define TEXTURE_H
