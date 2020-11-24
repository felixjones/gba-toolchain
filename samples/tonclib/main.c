#include <tonc.h>

int main( int argc, char * argv[] ) {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(92, 68);
    tte_write("Hello World!");

    irq_init(NULL);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();
    }

    return 0;
}
