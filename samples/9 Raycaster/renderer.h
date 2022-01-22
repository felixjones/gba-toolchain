/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef CAMERA_H
#define CAMERA_H
#ifdef __cplusplus
extern "C" {
#endif

extern int camera_angle;

void camera_update(int forward, int strafe, int page);

#ifdef __cplusplus
}
#endif
#endif // define CAMERA_H
