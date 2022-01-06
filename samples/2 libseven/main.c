#include <seven/prelude.h>
#include <seven/video/mode3.h>

int main(void)
{
    // TODO: irqInitDefault, irqInitSwitchboard
    irqInit(NULL);

    // TODO: irqEnableFull(IRQ_VBLANK);
    irqEnable(IRQ_VBLANK);
    REG_DISPSTAT = LCD_VBLANK_IRQ_ENABLE;

    lcdInitMode3();

    MODE3_FRAME[80][120] = RGB5(31,  0,  0);
    MODE3_FRAME[80][136] = RGB5( 0, 31,  0);
    MODE3_FRAME[96][120] = RGB5( 0,  0, 31);

    while (1)
    {
        svcVBlankIntrWait();
    }
}
