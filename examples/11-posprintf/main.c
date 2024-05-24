/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <posprintf.h>
#include <tonc.h>

int main() {
    irq_init(NULL);
    irq_enable(II_VBLANK);

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    char textBuffer[80];
    u16 lastKeys = 0xffff;
    while (1) {
        const u16 keys = REG_KEYINPUT;
        if (lastKeys != keys) {
            tte_erase_screen();
            tte_set_pos(48, 68);
            if (keys != 0x3ff) {
                posprintf(textBuffer, "REG_KEYINPUT: 0x%04x", keys);
                tte_write(textBuffer);
            } else {
                tte_write("Press a key");
            }
            lastKeys = keys;
        }
        VBlankIntrWait();
    }
}
