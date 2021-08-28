typedef volatile unsigned short vu16;
typedef volatile unsigned char vu8;

#define EZFLASH_SECTION_BOOTCHECK __attribute__((section(".ezflash._ezflash_bootcheck"), unused))

int _ezflash_rom_page;

static const volatile int * const rom_header = ( const volatile int * ) 0x080000a0;

static inline int EZFLASH_SECTION_BOOTCHECK ezflash_headcmp32( const int * a ) {
    for ( int ii = 0; ii < 8; ++ii ) {
        if ( a[ii] != rom_header[ii] ) {
            return 1;
        }
    }
    return 0;
}

static inline void EZFLASH_SECTION_BOOTCHECK ezflash_set_rompage( const unsigned int page ) {
    *( vu16 * ) 0x9fe0000 = 0xd200;
    *( vu16 * ) 0x8000000 = 0x1500;
    *( vu16 * ) 0x8020000 = 0xd200;
    *( vu16 * ) 0x8040000 = 0x1500;
    *( vu16 * ) 0x9880000 = ( unsigned short ) page;
    *( vu16 * ) 0x9fc0000 = 0x1500;
}

static inline void EZFLASH_SECTION_BOOTCHECK ezflash_rompage_asciiz( char * const ascii ) {
    ascii[0] = ( char ) ( _ezflash_rom_page / 100u );
    if ( ascii[0] ) ascii[0] += '0';

    ascii[1] = ( _ezflash_rom_page % 100u ) / 10u;
    if ( ascii[1] ) ascii[1] += '0';

    ascii[2] = '0' + ( _ezflash_rom_page % 10u );
    ascii[3] = 0;
}

int EZFLASH_SECTION_BOOTCHECK _ezflash_bootcheck( char currentPage[4] ) {
    int romHeader[8];

    for ( int ii = 0; ii < 8; ++ii ) {
        romHeader[ii] = rom_header[ii];
    }

    ezflash_set_rompage( 0x8000 );

    // Header hasn't changed
    if ( ezflash_headcmp32( romHeader ) == 0 ) {
        return 0;
    }

    // Detect EZ Flash Omega
    const int isOmega = ( rom_header[0] == 0 );

    // Find our ROM page
    _ezflash_rom_page = 0x200 + 1;
    while ( _ezflash_rom_page-- ) {
        ezflash_set_rompage( _ezflash_rom_page );
        if ( ezflash_headcmp32( romHeader ) == 0 ) {
            ezflash_rompage_asciiz( currentPage );
            break;
        }
    }

    return 1 + isOmega;
}
