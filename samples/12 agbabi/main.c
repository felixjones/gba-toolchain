/*
===============================================================================

 Prints a fixed-point representation of pi using agbabi

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <agbabi.h>
#include <tonc.h>

static const int precision = 30;
static const unsigned int pi = (unsigned int) ((1u << precision) * (3.1415926535897932384626433832795028841971693));

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(28, 60);

    char buffer[40];
    __agbabi_ufixed_tostr(pi, buffer, precision);

    tte_write(buffer);

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();
    }
}
