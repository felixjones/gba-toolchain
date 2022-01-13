/*
===============================================================================

 Simple GBFS based Multiboot ROM sender

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <agbabi.h>
#include <tonc.h>
#include <gbfs.h>

extern const GBFS_FILE payload_bin[];

static int mb_callback(int stat, int data, void* uptr);

int main() {
    u32 clientSize;
    const void * clientBinary = gbfs_get_obj(payload_bin, "client_mb.bin", &clientSize);

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(45, 68);

    irq_init(NULL);
    irq_enable(II_VBLANK);

    if (clientBinary) {
        tte_write("Press (A) to send Multiboot");

        while (1) {
            key_poll();
            VBlankIntrWait();
            if (key_hit(KEY_A)) {
                break;
            }
        }

        tte_erase_screen();
        tte_write("Sending Multiboot");

        const agbabi_mb_param_t param = {
            .srcp = clientBinary,
            .srclen = clientSize,
            .client_mask = 0xf,
            .palette = 0x81,
            .callback = mb_callback,
            .uptr = NULL
        };

        REG_IME = 0; // Disable interrupts during sending protocol
        const int status = __agbabi_multiboot(&param);
        REG_IME = 1;

        tte_erase_screen();
        if (status) {
            tte_write( "Failed to send Multiboot" );
        } else {
            tte_write( "Multiboot sent!" );
        }
    } else {
        tte_write("Failed to find client binary");
    }

    while (1) {
        VBlankIntrWait();
    }
}

static int mb_callback(int stat, int data, void* uptr) {
    if (stat == agbabi_mb_WAIT) {
        REG_IME = 1;
        for (int frames = 0; frames < 128; ++frames) {
            VBlankIntrWait();
        }
        REG_IME = 0;
    }

    return 0;
}
