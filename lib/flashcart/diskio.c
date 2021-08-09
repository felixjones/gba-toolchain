#include "diskio.h"

disk_io_tab_t _disk_io_tab;

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

time_type get_fattime() {
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
            disk_overlay_set( &__load_start_disk1, &__disk_overlay, ( int ) __disk1_cpuset_copy );
            break;
        case 6: // EZFlash
            _disk_io_tab.status = _ezflash_disk_status;
            _disk_io_tab.initialize = _ezflash_disk_initialize;
            _disk_io_tab.read = _ezflash_disk_read;
            _disk_io_tab.write = _ezflash_disk_write;
            _disk_io_tab.ioctl = _ezflash_disk_ioctl;
            _disk_io_tab.fattime = _ezflash_disk_fattime;
            disk_overlay_set( &__load_start_disk2, &__disk_overlay, ( int ) __disk2_cpuset_copy );
            break;
    }
}
