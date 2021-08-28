#include "diskio.h"

#define SECTION_DISK_CODE __attribute__((section(".disk1.text"), target("arm"), unused))

dstatus_type _ezflash_iv_disk_status( pdrv_type pdrv ) {
    return dresult_not_ready;
}

dresult_type _ezflash_iv_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff ) {
    switch ( cmd ) {
#if FF_MAX_SS > FF_MIN_SS
    case cmd_get_sector_size:
        *( int * ) buff = SECTOR_SIZE;
        break;
#endif
    default:
        __builtin_unreachable();
    }
    return dresult_not_ready;
}

dresult_type _ezflash_iv_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count ) {
    return dresult_not_ready;
}

dresult_type _ezflash_iv_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count ) {
    return dresult_not_ready;
}

dstatus_type _ezflash_iv_disk_initialize( pdrv_type pdrv ) {
    return dresult_not_ready;
}
