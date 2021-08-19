#include "diskio.h"

#include "fatfs/source/ff.h"

#define SECTION_EWRAM_DATA __attribute__((section(".ewram.data")))

extern unsigned int _disk_status;

disk_io_tab_t _disk_io_tab SECTION_EWRAM_DATA;

dstatus_type disk_initialize( pdrv_type pdrv ) {
    return _disk_io_tab.initialize( pdrv );
}

dstatus_type disk_status( pdrv_type pdrv ) {
    return _disk_io_tab.status( pdrv );
}

dresult_type disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count ) {
    return _disk_io_tab.read( pdrv, buff, sector, count );
}

dresult_type disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count ) {
    return _disk_io_tab.write( pdrv, buff, sector, count );
}

dresult_type disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff ) {
    return _disk_io_tab.ioctl( pdrv, cmd, buff );
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

static time_type _none_fattime() {
    return 0;
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

#define RED ( 0x001f )
#define GRN ( 0x001f << 5 )
#define BLU ( 0x001f << 10 )
#define YLW ( RED | GRN )
#define CYN ( GRN | BLU )
#define MAG ( RED | BLU )
static void debug_pixel( int x, int y, uint16_t c ) {
//    *( volatile uint16_t * ) 0x04000000 = 0x0403;
//    ( ( volatile uint16_t * ) 0x06000000 )[x+y*240] = c;
}

static void debug_plot16( int x, int y, uint16_t value ) {
    debug_pixel( x, y, RED );
    for ( int ii = 0; ii < 16; ++ii ) {
        if ( value & 0x8000 ) {
            debug_pixel( x + 1 + ii, y, 0xffff );
        } else {
            debug_pixel( x + 1 + ii, y, 0x0000 );
        }
        value <<= 1;
    }
    debug_pixel( x + 17, y, RED );
}

#include "../tonc/include/tonc.h"
#include "../posprintf/posprintf.h"

void _disk_io_init( int type ) {
    switch ( type ) {
        default:
            _disk_io_tab.status = _none_disk_status_initialize;
            _disk_io_tab.initialize = _none_disk_status_initialize;
            _disk_io_tab.read = _none_disk_read;
            _disk_io_tab.write = _none_disk_write;
            _disk_io_tab.ioctl = _none_disk_ioctl;
            _disk_io_tab.fattime = _none_fattime;
            break;
        case 4: // Flash1M
            _disk_io_tab.status = _flash_disk_status;
            _disk_io_tab.initialize = _flash_disk_initialize;
            _disk_io_tab.read = _flash_disk_read;
            _disk_io_tab.write = _flash_disk_write;
            _disk_io_tab.ioctl = _flash_disk_ioctl;
            _disk_io_tab.fattime = _flash_disk_fattime;
            disk_overlay_set( &__load_start_disk0, &__disk_overlay, ( int ) __disk0_cpuset_copy );
            break;
        case 5: // Everdrive
            _disk_io_tab.status = _everdrive_disk_status;
            _disk_io_tab.initialize = _everdrive_disk_initialize;
            _disk_io_tab.read = _everdrive_disk_read;
            _disk_io_tab.write = _everdrive_disk_write;
            _disk_io_tab.ioctl = _everdrive_disk_ioctl;
            _disk_io_tab.fattime = _everdrive_disk_fattime;
            break;
        case 6: // EZFlash
            _disk_io_tab.status = _ezflash_disk_status;
            _disk_io_tab.initialize = _ezflash_disk_initialize;
            _disk_io_tab.read = _ezflash_disk_read;
            _disk_io_tab.write = _ezflash_disk_write;
            _disk_io_tab.ioctl = _ezflash_disk_ioctl;
            _disk_io_tab.fattime = _ezflash_disk_fattime;
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
