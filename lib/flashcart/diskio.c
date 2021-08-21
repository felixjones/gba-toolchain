#include "diskio.h"

#include <rtc.h>
#include "fatfs/source/ff.h"

#define SECTION_EWRAM_DATA __attribute__((section(".ewram.data")))

#define REG_IME ( *( volatile unsigned short * ) 0x04000208 )

extern unsigned int _disk_status;

disk_io_tab_t _disk_io_tab SECTION_EWRAM_DATA;

dstatus_type disk_initialize( pdrv_type pdrv ) {
    const int ime = REG_IME;
    REG_IME = 0;
    const dstatus_type status = _disk_io_tab.initialize( pdrv );
    REG_IME = ime;
    return status;
}

dstatus_type disk_status( pdrv_type pdrv ) {
    const int ime = REG_IME;
    REG_IME = 0;
    const dstatus_type status = _disk_io_tab.status( pdrv );
    REG_IME = ime;
    return status;
}

dresult_type disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count ) {
    const int ime = REG_IME;
    REG_IME = 0;
    const dresult_type result = _disk_io_tab.read( pdrv, buff, sector, count );
    REG_IME = ime;
    return result;
}

dresult_type disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count ) {
    const int ime = REG_IME;
    REG_IME = 0;
    const dresult_type result = _disk_io_tab.write( pdrv, buff, sector, count );
    REG_IME = ime;
    return result;
}

dresult_type disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff ) {
    const int ime = REG_IME;
    REG_IME = 0;
    const dresult_type result = _disk_io_tab.ioctl( pdrv, cmd, buff );
    REG_IME = ime;
    return result;
}

DWORD get_fattime() {
    return _disk_io_tab.fattime();
}

static dstatus_type _none_disk_status_initialize( pdrv_type pdrv ) {
    return 0;
}

static dresult_type _none_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count ) {
    return dresult_ok;
}

static dresult_type _none_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count ) {
    return dresult_ok;
}

static dresult_type _none_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff ) {
    return dresult_ok;
}

#define bcd_decode( x ) ( ( ( x ) & 0xfu ) + ( ( ( x ) >> 4u ) * 10u ) )

time_type _rtc_disk_fattime() {
    const int ime = REG_IME;
    REG_IME = 0;
    const rtc_tm datetime = __rtc_get_datetime();
    REG_IME = ime;

    const uint32_t year = bcd_decode( RTC_TM_YEAR( datetime ) ) + ( 2000u - 1980u );
    const uint32_t month = bcd_decode( RTC_TM_MON( datetime ) );
    const uint32_t day = bcd_decode( RTC_TM_MDAY( datetime ) );

    const uint32_t hour = bcd_decode( RTC_TM_HOUR( datetime ) );
    const uint32_t minute = bcd_decode( RTC_TM_MIN( datetime ) );
    const uint32_t second = bcd_decode( RTC_TM_SEC( datetime ) );

    return ( year << 25u ) | ( month << 21u ) | ( day << 16u ) | ( hour << 11u ) | ( minute << 5u ) | ( second >> 1u );
}

extern int __disk_overlay;

static void __attribute__((naked)) disk_overlay_set( const void * source, void * destination, int lengthmode ) {
    __asm__ volatile (
#if defined( __thumb__ )
        "swi\t%[Swi]\n"
#elif defined( __arm__ )
        "swi\t%[Swi] << 16\n"
#endif
        "bx\tlr"
        :: [Swi]"i"( 0xb ) : "r0", "r1", "r2", "r3"
    );
}

static FATFS fat_file_system SECTION_EWRAM_DATA;
int _dsk_rtc SECTION_EWRAM_DATA;

void _disk_io_init( int type ) {
    if ( type == 4 || type == 5 || type == 6 ) {
        _dsk_rtc = __rtc_init();
    } else {
        _dsk_rtc = -1;
    }

    switch ( type ) {
        default:
            _disk_io_tab.status = _none_disk_status_initialize;
            _disk_io_tab.initialize = _none_disk_status_initialize;
            _disk_io_tab.read = _none_disk_read;
            _disk_io_tab.write = _none_disk_write;
            _disk_io_tab.ioctl = _none_disk_ioctl;
            _disk_io_tab.fattime = _rtc_disk_fattime;
            break;
        case 4: // Flash1M
            _disk_io_tab.status = _flash_disk_status;
            _disk_io_tab.initialize = _flash_disk_initialize;
            _disk_io_tab.read = _flash_disk_read;
            _disk_io_tab.write = _flash_disk_write;
            _disk_io_tab.ioctl = _flash_disk_ioctl;
            _disk_io_tab.fattime = _rtc_disk_fattime;
            disk_overlay_set( &__load_start_disk0, &__disk_overlay, ( int ) __disk0_cpuset_copy );
            break;
        case 5: // Everdrive
            _disk_io_tab.status = _everdrive_disk_status;
            _disk_io_tab.initialize = _everdrive_disk_initialize;
            _disk_io_tab.read = _everdrive_disk_read;
            _disk_io_tab.write = _everdrive_disk_write;
            _disk_io_tab.ioctl = _everdrive_disk_ioctl;
            _disk_io_tab.fattime = _rtc_disk_fattime;
            break;
        case 6: // EZFlash
            _disk_io_tab.status = _ezflash_disk_status;
            _disk_io_tab.initialize = _ezflash_disk_initialize;
            _disk_io_tab.read = _ezflash_disk_read;
            _disk_io_tab.write = _ezflash_disk_write;
            _disk_io_tab.ioctl = _ezflash_disk_ioctl;
            _disk_io_tab.fattime = _rtc_disk_fattime;
            disk_overlay_set( &__load_start_disk1, &__disk_overlay, ( int ) __disk1_cpuset_copy );
            break;
    }

    FRESULT mountResult = f_mount( &fat_file_system, "", 1 );
    if ( mountResult == FR_NO_FILESYSTEM && type == 4 ) {
        char workingArea[512];
        mountResult = f_mkfs( "", 0, workingArea, sizeof( workingArea ) );
    }
    _disk_status = ( mountResult == FR_OK );
}
