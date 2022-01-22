/*
===============================================================================

 Simple GBFS hello world

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>
#include <gbfs.h>
#include <malloc.h>
#include <string.h>

#ifndef ASSETS_GBFS
extern const GBFS_FILE assets_gbfs[];
#else
extern const char __rom_end[];
#endif

int main() {
#ifdef ASSETS_GBFS
    const GBFS_FILE * const assets_gbfs = find_first_gbfs_file(__rom_end);
#endif
    u32 textSize;
    const void * textBinary = gbfs_get_obj(assets_gbfs, "hello.txt", &textSize);

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(92, 68);
    if (!textBinary) {
        tte_write( "Could not find hello.txt" );
    } else {
        char * buffer = malloc(textSize + 1);
        memcpy(buffer, textBinary, textSize);
        buffer[textSize] = 0;

        tte_write(buffer);

        free(buffer);
    }

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();
    }
}
