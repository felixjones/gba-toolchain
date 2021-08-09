#include "diskio.h"

#define SECTION_DISK_CODE __attribute__((section(".disk0.text"), target("arm"), unused))

#define SECTION_ROM_CODE __attribute__((section(".text"), target("thumb"), unused))

#define SECTOR_SIZE     ( 512u )
#define SECTOR_COUNT    ( 131072u / SECTOR_SIZE )
#define BANK_SIZE       ( 0x10000u )

dstatus_type SECTION_ROM_CODE _flash_disk_status( pdrv_type drv ) {
    return dresult_ok;
}

time_type _flash_disk_fattime() __attribute__((alias("_flash_disk_status")));

dresult_type SECTION_DISK_CODE _flash_disk_ioctl( pdrv_type drv, cmd_type cmd, void * buff ) {
    switch ( cmd ) {
        case cmd_get_sector_count:
            *( int * ) buff = SECTOR_COUNT;
            break;
        case cmd_get_sector_size:
            *( int * ) buff = SECTOR_SIZE;
            break;
        case cmd_get_block_size:
            *( int * ) buff = 1;
            break;
    }
    return dresult_ok;
}

static inline void SECTION_DISK_CODE set_waitcnt( uint16_t value ) {
    *( volatile uint16_t * ) 0x4000204 = value;
}

static inline uint16_t SECTION_DISK_CODE set_waitcnt8() {
    const uint16_t value = *( volatile uint16_t * ) 0x4000204;
    set_waitcnt( value | 0x300 );
    return value;
}

static inline void SECTION_DISK_CODE set_mode( byte_type mode ) {
    *( volatile byte_type * ) 0xE005555 = 0xaa;
    *( volatile byte_type * ) 0xE002aaa = 0x55;
    *( volatile byte_type * ) 0xE005555 = mode;
}

dstatus_type SECTION_DISK_CODE _flash_disk_initialize( pdrv_type drv ) {
    const uint16_t waitcnt = set_waitcnt8();

    set_mode( 0xb0 );
    *( volatile byte_type * ) 0xE000000 = 1u;

    set_mode( 0xf0 );
    *( volatile byte_type * ) ( 0xE00ffff );

    set_waitcnt( waitcnt );
    return dresult_ok;
}

dresult_type SECTION_DISK_CODE _flash_disk_read( pdrv_type drv, byte_type * buff, uint_type sector, uint_type count ) {
    const uint_type startByte = sector * SECTOR_SIZE;
    const uint_type startBank = startByte / BANK_SIZE;
    uint_type numBytes = count * SECTOR_SIZE;
    const uint_type endBank = startBank + numBytes / BANK_SIZE;

    const uint16_t waitcnt = set_waitcnt8();

    const uint_type baseAddress = 0xE000000 + startByte;
    uint_type bank = startBank;
    do {
        set_mode( 0xb0 );
        *( volatile byte_type * ) 0xE000000 = bank;
        set_mode( 0xf0 );

        const uint_type len = ( numBytes > BANK_SIZE ? BANK_SIZE : numBytes );
        numBytes -= BANK_SIZE;
        for ( int ii = 0; ii < len; ++ii ) {
            volatile byte_type * address = ( volatile byte_type * ) ( baseAddress + ii );

            *buff++ = *address;
        }
    } while ( ++bank < endBank );

    set_waitcnt( waitcnt );
    return dresult_ok;
}

dresult_type SECTION_DISK_CODE _flash_disk_write( pdrv_type drv, const byte_type * buff, uint_type sector, uint_type count ) {
    const uint_type startByte = sector * SECTOR_SIZE;
    const uint_type startBank = startByte / BANK_SIZE;
    uint_type numBytes = count * SECTOR_SIZE;
    const uint_type endBank = startBank + numBytes / BANK_SIZE;

    const uint16_t waitcnt = set_waitcnt8();

    const uint_type baseAddress = 0xE000000 + startByte;
    uint_type bank = startBank;
    do {
        set_mode( 0xb0 );
        *( volatile byte_type * ) 0xE000000 = bank;

        const uint_type len = ( numBytes > BANK_SIZE ? BANK_SIZE : numBytes );
        numBytes -= BANK_SIZE;
        for ( int ii = 0; ii < len; ++ii ) {
            const byte_type value = *buff;
            volatile byte_type * address = ( volatile byte_type * ) ( baseAddress + ii );

            set_mode( 0xa0 );
            *address = value;
            set_mode( 0xf0 );
            while ( *address != value ) {}
            buff++;
        }
    } while ( ++bank < endBank );

    set_waitcnt( waitcnt );
    return dresult_ok;
}
