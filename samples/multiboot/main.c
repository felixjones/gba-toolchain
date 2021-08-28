#include <tonc.h>
#include <posprintf.h>
#include <comm.h>
#include <gbfs.h>

extern const GBFS_FILE assets_gbfs;

int main(void) {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    irq_init(NULL);
    irq_enable(II_VBLANK);

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(0, 0);

    u32 payloadLen;
    const void * payload = gbfs_get_obj(&assets_gbfs, "payload.mb", &payloadLen );
    if (!payload) {
        tte_write("Could not load payload.mb");
        goto loop_;
    }

    tte_write("Press A to send payload.mb\n");
    while (1) {
        key_poll();
        if (key_hit(KEY_A)) {
            break;
        }
        VBlankIntrWait();
    }

    int multibootStatus = __comm_multiboot_send( MB_CLIENT_ALL, payload, payloadLen, MB_PAL_ANIM( 1, 1, 1 ) );
    if (multibootStatus) {
        char buffer[40];
        posprintf(buffer, "Failed to send payload.mb (%04x)", multibootStatus);
        tte_write(buffer);
        goto loop_;
    }

    tte_write("payload.mb sent!");

loop_:
    while (1) {
        VBlankIntrWait();
    }

    return 0;
}
