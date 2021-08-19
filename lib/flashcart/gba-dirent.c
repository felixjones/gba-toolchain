#include <stdlib.h>

#include "fatfs/source/ff.h"

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
