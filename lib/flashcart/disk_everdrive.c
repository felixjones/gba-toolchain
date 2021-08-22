#include "diskio.h"

#include <stddef.h>

#define SECTOR_SIZE ( 512 )

dstatus_type _everdrive_disk_status( pdrv_type drv ) {
    return dresult_ok;
}

dresult_type _everdrive_disk_ioctl( pdrv_type drv, cmd_type cmd, void * buff ) {
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

int _everdrive_init();
int _everdrive_read( uintptr_t sd_addr, void * dst, size_t slen );
int _everdrive_write( uintptr_t sd_addr, const void * src, size_t slen );

dstatus_type _everdrive_disk_initialize( pdrv_type drv ) {
    if ( _everdrive_init() ) {
        return 1;
    }
    return 0;
}

dresult_type _everdrive_disk_read( pdrv_type drv, byte_type * buff, uint_type sector, uint_type count ) {
    if ( _everdrive_read( sector, buff, count ) ) {
        return dresult_error;
    }
    return dresult_ok;
}

dresult_type _everdrive_disk_write( pdrv_type drv, const byte_type * buff, uint_type sector, uint_type count ) {
    if ( _everdrive_write( sector, buff, count ) ) {
        return dresult_error;
    }
    return dresult_ok;
}
