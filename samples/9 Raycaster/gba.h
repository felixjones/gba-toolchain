/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef GBA_H
#define GBA_H
#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

typedef volatile u32 vu32;
typedef volatile u16 vu16;
typedef volatile u8 vu8;

#define REG_DISPCNT ((vu16*) 0x4000000)
#define REG_KEYINPUT ((vu16*) 0x4000130)

#define PALMEM ((u16*) 0x5000000)
#define FRAME_BUFFER ((u8*) 0x6000000)
#define FRAME_BUFFER_LEN 0xa000

#define MODE4_BG2 0x0404

#define PAGE0 0x00
#define PAGE1 0x10

#define KEY_A 0x0001
#define KEY_B 0x0002
#define KEY_SELECT 0x0004
#define KEY_START 0x0008
#define KEY_RIGHT 0x0010
#define KEY_LEFT 0x0020
#define KEY_UP 0x0040
#define KEY_DOWN 0x0080
#define KEY_R 0x0100
#define KEY_L 0x0200

#ifdef __cplusplus
}
#endif
#endif // define GBA_H
