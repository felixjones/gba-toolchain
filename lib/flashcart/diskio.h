#ifndef _FLASHCART_DISKIO_H_
#define _FLASHCART_DISKIO_H_

#include <stdint.h>

typedef unsigned char byte_type;
typedef unsigned int uint_type;

typedef uint_type pdrv_type;
typedef uint_type dstatus_type;
typedef enum dresult_type {
    dresult_ok = 0,
    dresult_error = 1,
    dresult_parameter_error = 2,
    dresult_not_ready = 3,

    uint32_max_dresult = UINT32_MAX
} dresult_type;
typedef enum cmd_type {
    cmd_control_sync = 0,
    cmd_get_sector_count = 1,
    cmd_get_sector_size = 2,
    cmd_get_block_size = 3,
    cmd_control_trim = 4,

    uint32_max_cmd = UINT32_MAX
} cmd_type;
typedef uint_type time_type;

typedef struct disk_io_tab_t {
    dstatus_type ( * status )( pdrv_type );
    dstatus_type ( * initialize )( pdrv_type );
    dresult_type ( * read )( pdrv_type, byte_type *, uint_type, uint_type );
    dresult_type ( * write )( pdrv_type, const byte_type *, uint_type, uint_type );
    dresult_type ( * ioctl )( pdrv_type, cmd_type, void * );
    time_type ( * fattime )();
} disk_io_tab_t;

extern disk_io_tab_t _disk_io_tab;

dstatus_type _flash_disk_status( pdrv_type );
dstatus_type _flash_disk_initialize( pdrv_type );
dresult_type _flash_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count );
dresult_type _flash_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count );
dresult_type _flash_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff );

dstatus_type _everdrive_disk_status( pdrv_type );
dstatus_type _everdrive_disk_initialize( pdrv_type );
dresult_type _everdrive_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count );
dresult_type _everdrive_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count );
dresult_type _everdrive_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff );
extern int __load_start_disk0;
extern int __disk0_cpuset_copy[];

dstatus_type _ezflash_iv_disk_status( pdrv_type );
dstatus_type _ezflash_iv_disk_initialize( pdrv_type );
dresult_type _ezflash_iv_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count );
dresult_type _ezflash_iv_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count );
dresult_type _ezflash_iv_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff );
extern int __load_start_disk1;
extern int __disk1_cpuset_copy[];

dstatus_type _ezflash_omega_disk_status( pdrv_type );
dstatus_type _ezflash_omega_disk_initialize( pdrv_type );
dresult_type _ezflash_omega_disk_read( pdrv_type pdrv, byte_type * buff, uint_type sector, uint_type count );
dresult_type _ezflash_omega_disk_write( pdrv_type pdrv, const byte_type * buff, uint_type sector, uint_type count );
dresult_type _ezflash_omega_disk_ioctl( pdrv_type pdrv, cmd_type cmd, void * buff );
extern int __load_start_disk2;
extern int __disk2_cpuset_copy[];

#endif // define _FLASHCART_DISKIO_H_
