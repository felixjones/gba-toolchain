#include <stdlib.h>

#include <sys/stat.h>
#include <sys/time.h>
#include <errno.h>
#include "fatfs/source/ff.h"

#undef errno
extern int errno;

#define SECTION_EWRAM_DATA __attribute__((section(".ewram.data")))

extern unsigned int _disk_status;

static int dir_table_bits SECTION_EWRAM_DATA = 0;
static DIR dir_table[4] SECTION_EWRAM_DATA;
static FILINFO filinfo_table[4] SECTION_EWRAM_DATA;

static DIR * dir_table_alloc() {
    for ( int ii = 0; ii < 4; ++ii ) {
        const int mask = ( 1 << ii );
        if ( ( dir_table_bits & mask ) == 0 ) {
            dir_table_bits |= mask;
            return &dir_table[ii];
        }
    }
    return NULL;
}

static void dir_table_free( DIR * const dp ) {
    const int idx = ( dp - &dir_table[0] ) / (int) sizeof( *dp );
    const int mask = ( 1 << idx );
    dir_table_bits &= ~mask;
}

static FILINFO * dir_filinfo( DIR * const dp ) {
    const int idx = ( dp - &dir_table[0] ) / (int) sizeof( *dp );
    return &filinfo_table[idx];
}

DIR * opendir( const char * dirname ) {
    if ( !_disk_status ) {
        return NULL;
    }

    DIR * const dp = dir_table_alloc();
    if ( !dp ) {
        return NULL;
    }

    if ( f_opendir( dp, dirname ) != FR_OK ) {
        dir_table_free( dp );
        return NULL;
    }

    return dp;
}

int closedir( DIR * dirp ) {
    if ( !_disk_status ) {
        return -1;
    }

    dir_table_free( dirp );

    if ( f_closedir( dirp ) != FR_OK ) {
        return -1;
    }

    return 0;
}

struct dirent * readdir( DIR * dirp ) {
    if ( !_disk_status ) {
        return NULL;
    }

    FILINFO * const filinfo = dir_filinfo( dirp );
    if ( f_readdir( dirp, filinfo ) != FR_OK || filinfo->fname[0] == 0 ) {
        return NULL;
    }

    return ( struct dirent * ) filinfo;
}

int	mkdir( const char * path, mode_t mode ) {
    if ( !_disk_status ) {
        errno = EIO;
        return -1;
    }

    FRESULT result = f_mkdir( path );
    if ( result != FR_OK ) {
        switch ( result ) {
            default:
                errno = EIO;
                break;
            case FR_NO_PATH:
            case FR_INVALID_NAME:
            case FR_INVALID_DRIVE:
                errno = ENOENT;
                break;
            case FR_DENIED:
            case FR_WRITE_PROTECTED:
                errno = EACCES;
                break;
            case FR_EXIST:
                errno = EEXIST;
                break;
            case FR_NOT_ENOUGH_CORE:
                errno = ENOSPC;
                break;
        }
        return -1;
    }

    if ( mode ) {
        f_chmod( path, mode, 0x37 );
    }
    return 0;
}

int utimes( const char * filename, const struct timeval times[2] ) {
    if ( !_disk_status ) {
        return -1;
    }

    FILINFO finfo;
    if ( !times ) {
        const DWORD fatTime = get_fattime();
        finfo.fdate = fatTime >> 16;
        finfo.ftime = fatTime;
    } else {
        const struct tm * tmptr = gmtime( &times[1].tv_sec );

        finfo.fdate = ( ( tmptr->tm_year - 80 ) << 9 ) | ( ( tmptr->tm_mon + 1 ) << 5 ) | tmptr->tm_mday;
        finfo.ftime = ( ( tmptr->tm_hour + 1 ) << 11 ) | ( tmptr->tm_min << 5 ) | ( tmptr->tm_sec >> 1 );
    }

    if ( f_utime( filename, &finfo ) != FR_OK ) {
        return -1;
    }
    return 0;
}
