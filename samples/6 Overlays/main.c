/*
===============================================================================

 Sample memory overlay GBA project

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>

#define EWRAM0  __attribute__((section(".ewram0")))
#define EWRAM1  __attribute__((section(".ewram1")))
#define EWRAM2  __attribute__((section(".ewram2")))
#define EWRAM3  __attribute__((section(".ewram3")))

extern u32 __ewram_overlay[];

EWRAM0 void print_up() {
    tte_erase_screen();
    tte_set_pos(92, 68);
    tte_write("Up");
}
extern u32 __load_start_ewram0[];
extern u32 __load_stop_ewram0[];

EWRAM1 void print_down() {
    tte_erase_screen();
    tte_set_pos(92, 68);
    tte_write("Down");
}
extern u32 __load_start_ewram1[];
extern u32 __load_stop_ewram1[];

EWRAM2 void print_left() {
    tte_erase_screen();
    tte_set_pos(92, 68);
    tte_write("Left");
}
extern u32 __load_start_ewram2[];
extern u32 __load_stop_ewram2[];

EWRAM3 void print_right() {
    tte_erase_screen();
    tte_set_pos(92, 68);
    tte_write("Right");
}
extern u32 __load_start_ewram3[];
extern u32 __load_stop_ewram3[];

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(45, 68);
    tte_write("Press Direction to change overlay");

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        key_poll();
        VBlankIntrWait();
        if (key_hit(KEY_UP)) {
            const u32 ewram_size = __load_stop_ewram0 - __load_start_ewram0;
            CpuSet(__load_start_ewram0, __ewram_overlay, ewram_size | CS_CPY32);
            print_up();
        }
        if (key_hit(KEY_DOWN)) {
            const u32 ewram_size = __load_stop_ewram1 - __load_start_ewram1;
            CpuSet(__load_start_ewram1, __ewram_overlay, ewram_size | CS_CPY32);
            print_down();
        }
        if (key_hit(KEY_LEFT)) {
            const u32 ewram_size = __load_stop_ewram2 - __load_start_ewram2;
            CpuSet(__load_start_ewram2, __ewram_overlay, ewram_size | CS_CPY32);
            print_left();
        }
        if (key_hit(KEY_RIGHT)) {
            const u32 ewram_size = __load_stop_ewram3 - __load_start_ewram3;
            CpuSet(__load_start_ewram3, __ewram_overlay, ewram_size | CS_CPY32);
            print_right();
        }
    }
}
