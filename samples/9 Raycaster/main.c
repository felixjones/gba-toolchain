/*
===============================================================================

 Raycaster demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "gba.h"

#include <stddef.h>
#include <gbfs.h>
#include <agbabi.h>

#include "texture.h"
#include "map.h"
#include "renderer.h"

#ifndef ASSETS_GBFS
extern const GBFS_FILE assets_gbfs[];
#else
extern const char __rom_end[];
#endif

#define KEY_RESET_COMBO (KEY_A | KEY_B | KEY_SELECT | KEY_START)

const texture_type* texture_memory;
const map_type* map_memory;

static void bios_vblank();

int main() {
#ifdef ASSETS_GBFS
    const GBFS_FILE* const assets_gbfs = find_first_gbfs_file(__rom_end);
#endif
    *REG_DISPCNT = MODE4_BG2;
    *REG_DISPSTAT = DISPSTAT_VBLANK;
    *REG_IE = IRQ_VBLANK;
    *IRQ_HANDLER = __agbabi_irq_empty;
    *REG_IME = 1;

    u32 palSize;
    const void* palBinary = gbfs_get_obj(assets_gbfs, "wolftextures.pal", &palSize);
    __agbabi_memcpy2(PALMEM, palBinary, palSize);

    u32 texSize;
    texture_memory = (const texture_type*) gbfs_get_obj(assets_gbfs, "wolftextures.bin", &texSize);

    u32 mapSize;
    map_memory = (const map_type*) gbfs_get_obj(assets_gbfs, "map.bin", &mapSize);

    int page = 0;
    u32 keys = *REG_KEYINPUT;
    while (keys & KEY_RESET_COMBO) {
        // Poll keys
        keys = (keys << 16) | *REG_KEYINPUT;

        int mz = 0, mx = 0;
        if ((keys & KEY_LEFT) == 0) camera_angle += 0x100;
        if ((keys & KEY_RIGHT) == 0) camera_angle -= 0x100;
        if ((keys & KEY_L) == 0) mx--;
        if ((keys & KEY_R) == 0) mx++;
        if ((keys & KEY_UP) == 0) mz++;
        if ((keys & KEY_DOWN) == 0) mz--;

        page = 1 - page;
        camera_update(mz, mx, FRAME_BUFFER_LEN * page);
        bios_vblank();
        *REG_DISPCNT = MODE4_BG2 | (PAGE1 * page);
    }

    *REG_DISPCNT = 0;
    *REG_IME = 0;

    // Trap reset keys until they are let go
    do {
        keys = *REG_KEYINPUT;
    } while (!(keys & KEY_RESET_COMBO));
    return 0;
}

static void bios_vblank() {
    __asm__(
#if defined( __thumb__ )
        "swi\t%[Swi]"
#elif defined( __arm__ )
        "swi\t%[Swi] << 16"
#endif
        :: [Swi]"i"( 0x5 )
    );
}
