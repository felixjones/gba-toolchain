// From: https://github.com/AntonioND/ugba-testing/blob/master/examples/graphics/text_console/source/main.c
//
// SPDX-License-Identifier: MIT
//
// Copyright (c) 2020-2021 Antonio Niño Díaz

#include <ugba/ugba.h>

int main(int argc, char* argv[]) {
    UGBA_Init(&argc, &argv);

    IRQ_Enable(IRQ_VBLANK);

    DISP_ModeSet(0);

    CON_InitDefault();

    CON_Print("This is a text string");

    CON_CursorSet(10, 10);
    CON_Print("At 10, 10");

    CON_CursorSet(20, 12);
    CON_Print("This is a much longer string that wraps around and is\n"
        "split into lines\n");

    while (1) {
        SWI_VBlankIntrWait();

        KEYS_Update();

        const uint16_t keys = KEYS_Pressed();

        if (keys & KEY_B) {
            CON_Print("1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n"
                "11\n12\n13\n14\n15\n16\n17\n18\n19\n20\n");
        }

        if (keys & KEY_A) {
            CON_Print("\n\n\n\n");
        }

        if (keys & KEY_SELECT) {
            CON_CursorSet(28, 19);
            CON_Print("@");
        }
    }
}
