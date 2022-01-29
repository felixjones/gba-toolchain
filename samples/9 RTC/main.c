/*
===============================================================================

 RTC demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <agbabi.h>
#include <tonc.h>
#include <posprintf.h>

#include <time.h>

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(92, 68);

    const int noRtc = __agbabi_rtc_init();

    if (noRtc) {
        tte_write("Err");
    }

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();

        if (!noRtc) {
            time_t now = time(NULL);
            struct tm* time = localtime(&now);

            char buffer[80];
            posprintf(buffer, "Time: %02d:%02d:%02d", time->tm_hour, time->tm_min, time->tm_sec);

            tte_erase_screen();
            tte_set_pos(92, 68);
            tte_write(buffer);
        }
    }

    __builtin_unreachable();
}
