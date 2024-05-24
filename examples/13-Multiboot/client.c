/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <stdio.h>

#include <gba.h>

int main() {
    irqInit();
    irqEnable(IRQ_VBLANK);

    consoleDemoInit();

    iprintf("\x1b[10;10HHello World!\n");

    while (1) {
        VBlankIntrWait();
    }
}
