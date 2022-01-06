/*
===============================================================================

 "hello world" for e-reader

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(92, 68);
    tte_write("Hello, e-reader!");
    tte_set_pos(92, 80);
    tte_write("Hit (B) to exit");

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();
        key_poll();
        if (key_hit(KEY_B)) {
            break;
        }
    }
}
