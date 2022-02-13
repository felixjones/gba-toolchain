/*
===============================================================================

 Maxmod demo
 Adapted from https://github.com/devkitPro/gba-examples/tree/f220c93b0af95cf55beb02dc1bb3ea633115e2fe/audio/maxmod/basic_sound

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>
#include <gbfs.h>
#include <maxmod.h>

#include "soundbank.h"

#ifndef ASSETS_GBFS
extern const GBFS_FILE assets_gbfs[];
#else
extern const char __rom_end[];
#endif

int main() {
#ifdef ASSETS_GBFS
    const GBFS_FILE * const assets_gbfs = find_first_gbfs_file(__rom_end);
#endif
    u32 soundbank_size;
    const void * soundbank_bin = gbfs_get_obj(assets_gbfs, "soundbank.bin", &soundbank_size);

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;
    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));

    tte_erase_screen();
    tte_write("MaxMod Audio demo\nHold A for ambulance sound\nPress B for boom sound");

    irq_init(NULL);

    // Maxmod requires the vblank interrupt to reset sound DMA.
    // Link the VBlank interrupt to mmVBlank, and enable it.
    irq_add(II_VBLANK, mmVBlank);
    irq_enable(II_VBLANK);

    // initialise maxmod with soundbank and 8 channels
    mmInitDefault((mm_addr) soundbank_bin, 8);

    // Start playing module
    mmStart(MOD_FLATOUTLIES, MM_PLAY_LOOP);

    mm_sound_effect ambulance = {
        { SFX_AMBULANCE }, // id
        (int) (1<<10), // rate
        0, // handle
        255, // volume
        0, // panning
    };

    mm_sound_effect boom = {
        { SFX_BOOM }, // id
        (int) (1<<10), // rate
        0, // handle
        255, // volume
        255, // panning
    };

    // sound effect handle (for cancelling it later)
    mm_sfxhand amb = 0;

    while (1) {
        VBlankIntrWait();
        mmFrame();

        key_poll();

        // Play looping ambulance sound effect out of left speaker if A button is hit
        if (key_hit(KEY_A)) {
            amb = mmEffectEx(&ambulance);
        }
        // stop ambulance sound when A button is released
        if (amb && key_released(KEY_A)) {
            mmEffectCancel(amb);
            amb = 0;
        }

        // Play explosion sound effect out of right speaker if B button is hit
        if (key_hit(KEY_B)) {
            mmEffectEx(&boom);
        }
    }
}
