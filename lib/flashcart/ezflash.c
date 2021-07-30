typedef volatile unsigned short vu16;
typedef volatile unsigned char vu8;

#define EZFLASH_SECTION_BOOTCHECK __attribute__((section(".ezflash._ezflash_bootcheck"), unused))

static inline int EZFLASH_SECTION_BOOTCHECK _ezflash_headcmp32( const int * a ) {
    const volatile int * const rom_header = ( const volatile int * ) 0x080000a0;

    for ( int ii = 0; ii < 8; ++ii ) {
        if ( a[ii] != rom_header[ii] ) {
            return 1;
        }
    }
    return 0;
}

static inline void EZFLASH_SECTION_BOOTCHECK _ezflash_set_rompage( int page ) {
    *( vu16 * ) 0x9fe0000 = 0xd200;
    *( vu16 * ) 0x8000000 = 0x1500;
    *( vu16 * ) 0x8020000 = 0xd200;
    *( vu16 * ) 0x8040000 = 0x1500;
    *( vu16 * ) 0x9880000 = page;
    *( vu16 * ) 0x9fc0000 = 0x1500;
}

int EZFLASH_SECTION_BOOTCHECK _ezflash_bootcheck() {
    const volatile int * const rom_header = ( const volatile int * ) 0x080000a0;

    int romHeader[8];
    for ( int ii = 0; ii < 8; ++ii ) {
        romHeader[ii] = rom_header[ii];
    }

    _ezflash_set_rompage( 0x8000 );

    // Header hasn't changed
    if ( _ezflash_headcmp32( romHeader ) == 0 ) {
        return 0;
    }

    // Find in PSRAM
    _ezflash_set_rompage( 0x200 );
    if ( _ezflash_headcmp32( romHeader ) == 0 ) {
        goto _return_1;
    }

    // Find in NOR pages
    for ( int nor = 0; nor < 0x200; ++nor ) {
        _ezflash_set_rompage( nor );
        if ( _ezflash_headcmp32( romHeader ) == 0 ) {
            goto _return_1;
        }
    }

_return_1:
    return 1;
}
