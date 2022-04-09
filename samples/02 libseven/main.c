#include <seven/prelude.h>
#include <seven/video/prelude.h>
#include <seven/video/bg_bitmap.h>

int main(void)
{
    irqInitDefault();
    irqEnableFull(IRQ_VBLANK);

    REG_DISPCNT = VIDEO_MODE_BITMAP | VIDEO_BG2_ENABLE;

    MODE3_FRAME[80][120] = COLOR_RED;
    MODE3_FRAME[80][136] = COLOR_GREEN;
    MODE3_FRAME[96][120] = COLOR_BLUE;

    while (1)
    {
        svcVBlankIntrWait();
    }
}
