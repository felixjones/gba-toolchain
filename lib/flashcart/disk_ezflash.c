#include "diskio.h"

typedef volatile uint16_t vu16;
typedef volatile uint32_t vu32;

extern int _ezflash_rom_page;

#define SECTION_DISK_CODE __attribute__((section(".disk1.text"), target("arm"), unused))

#define SECTOR_SIZE     ( 512 )

#define SD_CMD_DISABLE  ( 0x0 )
#define SD_CMD_ENABLE   ( 0x1 )
#define SD_CMD_READ     ( 0x3 )

#define SD_RESPONSE ( *( ( vu16 * ) 0x9E00000 ) )

dstatus_type _ezflash_disk_status( pdrv_type drv ) {
    return dresult_ok;
}

dresult_type _ezflash_disk_ioctl( pdrv_type drv, cmd_type cmd, void * buff ) {
    switch ( cmd ) {
#if FF_MAX_SS > FF_MIN_SS
        case cmd_get_sector_size:
            *( int * ) buff = SECTOR_SIZE;
            break;
#endif
            default:
                __builtin_unreachable();
    }
    return dresult_ok;
}

dstatus_type _ezflash_disk_initialize( pdrv_type drv ) {
    return dresult_ok;
}

static inline void SECTION_DISK_CODE ezflash_cmd_prologue() {
    *( ( vu16 * ) 0x9fe0000 ) = 0xd200;
    *( ( vu16 * ) 0x8000000 ) = 0x1500;
    *( ( vu16 * ) 0x8020000 ) = 0xd200;
    *( ( vu16 * ) 0x8040000 ) = 0x1500;
}

static inline void SECTION_DISK_CODE ezflash_cmd_epilogue() {
    *( ( vu16 * ) 0x9fc0000 ) = 0x1500;
}

static inline void SECTION_DISK_CODE ezflash_set_rompage( const int page ) {
    ezflash_cmd_prologue();
    *( vu16 * ) 0x9880000 = page;
    ezflash_cmd_epilogue();
}

static inline void SECTION_DISK_CODE ezflash_sd_cmd( const int cmd ) {
    ezflash_cmd_prologue();
    *( ( ( vu16 * ) 0x9400000 ) ) = cmd;
    ezflash_cmd_epilogue();
}

static inline int SECTION_DISK_CODE ezflash_await_sd_response() {
    int timeout = 0x100000;
    while ( timeout-- ) {
        if ( SD_RESPONSE != 0xeee1 ) {
            return 0;
        }
    }
    return 1;
}

void SECTION_DISK_CODE __attribute__((naked)) ezflash_delay( int loops ) {
    __asm__(
        ".Lloop:\n\t"
        "cmp\tr0, #0\n\t"
        "bxeq\tlr\n\t"
        "sub\tr0, r0, #1\n\t"
        "b\t.Lloop"
    );
}

#define DMA_SRC *( ( vu32 * ) 0x40000D4 )
#define DMA_DST *( ( vu32 * ) 0x40000D8 )
#define DMA_LEN *( ( vu16 * ) 0x40000DC )
#define DMA_CTR *( ( vu16 * ) 0x40000DE )

dresult_type SECTION_DISK_CODE _ezflash_disk_read( pdrv_type drv, byte_type * buff, uint_type sector, uint_type count ) {
    ezflash_set_rompage( 0x8000 );
    ezflash_sd_cmd( SD_CMD_ENABLE );

    for ( int ii = 0; ii < count; ii += 4 ) {
        const int blocks = ( count - ii ) >= 4 ? 4 : ( int ) ( count - ii );
        int retries = 2;

        while ( 1 ) {
            ezflash_cmd_prologue();
            *( vu16 * ) 0x9600000 = sector;
            *( vu16 * ) 0x9620000 = sector >> 16;
            *( vu16 * ) 0x9640000 = blocks;
            ezflash_cmd_epilogue();

            ezflash_sd_cmd( SD_CMD_READ );
            const int timeout = ezflash_await_sd_response();
            ezflash_sd_cmd( SD_CMD_ENABLE );
            if ( timeout ) {
                if ( retries-- ) {
                    ezflash_delay( 500 );
                    continue;
                } else {
                    ezflash_sd_cmd( SD_CMD_DISABLE );
                    ezflash_set_rompage( _ezflash_rom_page );
                    return dresult_error;
                }
            }

            DMA_SRC = 0x9E00000;
            DMA_DST = ( uint32_t ) buff;
            DMA_LEN = ( SECTOR_SIZE / sizeof( uint16_t ) ) * blocks;
            DMA_CTR = 0x8000;
            break;
        }

        sector += blocks;
        buff += SECTOR_SIZE * blocks;
    }

    ezflash_sd_cmd( SD_CMD_DISABLE );
    ezflash_set_rompage( _ezflash_rom_page );
    return dresult_ok;
}

dresult_type SECTION_DISK_CODE _ezflash_disk_write( pdrv_type drv, const byte_type * buff, uint_type sector, uint_type count ) {
    ezflash_set_rompage( 0x8000 );
    ezflash_sd_cmd( SD_CMD_READ );

    for ( int ii = 0; ii < count; ii += 4 ) {
        const int blocks = ( count - ii ) >= 4 ? 4 : ( int ) ( count - ii );

        DMA_SRC = ( uint32_t ) buff;
        DMA_DST = 0x9E00000;
        DMA_LEN = ( SECTOR_SIZE / sizeof( uint16_t ) ) * blocks;
        DMA_CTR = 0x8000;

        ezflash_cmd_prologue();
        *( vu16 * ) 0x9600000 = sector;
        *( vu16 * ) 0x9620000 = sector >> 16;
        *( vu16 * ) 0x9640000 = 0x8000 | blocks;
        ezflash_cmd_epilogue();

        if ( ezflash_await_sd_response() ) {
            ezflash_delay( 3000 );

            ezflash_sd_cmd( SD_CMD_DISABLE );
            ezflash_set_rompage( _ezflash_rom_page );
            return dresult_error;
        }

        sector += blocks;
        buff += SECTOR_SIZE * blocks;
    }

    ezflash_delay( 3000 );

    ezflash_sd_cmd( SD_CMD_DISABLE );
    ezflash_set_rompage( _ezflash_rom_page );
    return dresult_ok;
}
