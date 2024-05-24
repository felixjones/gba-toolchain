/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>
#include <gbfs.h>

#include <assets.h>

int main() {
    irq_init(NULL);
    irq_enable(II_VBLANK);

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(92, 68);

    const char* text = gbfs_get_obj(((const GBFS_FILE*) assets_gbfs), "hello.txt", NULL);
    if (!text) {
        tte_write("Could not find hello.txt");
        goto skip;
    }

    tte_write(text);

skip:
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    while (1) {
        VBlankIntrWait();
    }
}
