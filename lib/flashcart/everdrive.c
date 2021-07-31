typedef volatile unsigned short vu16;
typedef volatile unsigned char vu8;

#define SECTION_BOOTCHECK __attribute__((section(".everdrive._everdrive_bootcheck"), unused))

int SECTION_BOOTCHECK _everdrive_bootcheck() {
    static const int * const rom_title = ( const int * ) 0x080000a0;
    static const int * const everdrive_title = ( const int * ) "BOOT-1\0\0\0\0\0\0EDGB";

    *( vu16 * ) 0x09fc00b4 = 0xa5;
    *( vu16 * ) 0x09fc0000 = 0x05;

    for ( int i = 0; i < 4; ++i ) {
        if ( rom_title[i] != everdrive_title[i] ) {
            *( vu16 * ) 0x09fc0000 = 0x02;
            return 0;
        }
    }

    *( vu16 * ) 0x09fc0000 = 0x02;
    return 1;
}
