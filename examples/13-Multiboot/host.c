/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <agbabi.h>
#include <tonc.h>

#include <host-assets.h>

static int on_clients_connected(int mask);
static int on_header_progress(int prog);
static int on_palette_progress(int mask);
static int on_multiboot_ready();

int main() {
    irq_init(NULL);
    irq_enable(II_VBLANK);

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_erase_screen();
    tte_write("Connect client then press (A) to send");

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    __agbabi_multiboot_t param;
    param.header = _13_Multiboot_client_gba;
    param.begin = _13_Multiboot_client_gba + 0xc0;
    param.end = _13_Multiboot_client_gba + _13_Multiboot_client_gba_len;
    param.palette = 0;
    param.clients_connected = on_clients_connected;
    param.header_progress = on_header_progress;
    param.palette_progress = on_palette_progress;
    param.accept = on_multiboot_ready;

    while (1) {
        key_poll();
        if (key_hit(KEY_A)) {
            tte_erase_screen();
            tte_set_pos(0, 0);
            tte_write("Sending...");
            if (__agbabi_multiboot(&param) != 0) {
                tte_write("Error");
            } else {
                tte_write("Success");
            }
        }
        VBlankIntrWait();
    }
}

static int on_clients_connected(int mask) {
    return 0;
}

static int on_header_progress(int prog) {
    return 0;
}

static int on_palette_progress(int mask) {
    return 0;
}

static int on_multiboot_ready() {
    return 0;
}
