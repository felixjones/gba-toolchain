#include <sys/stat.h>
#include <errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>

#include "fatfs/source/ff.h"

#undef errno
extern int errno;

#define SECTION_EWRAM_DATA __attribute__((section(".ewram.data")))

char * __env[1] = { 0 };
char ** environ = __env;
unsigned int _disk_status = 0;

static int file_table_bits SECTION_EWRAM_DATA = 0;
static FIL file_table[4] SECTION_EWRAM_DATA;

static FIL * file_table_alloc( int * idx ) {
    for ( int ii = 0; ii < 4; ++ii ) {
        const int mask = ( 1 << ii );
        if ( ( file_table_bits & mask ) == 0 ) {
            file_table_bits |= mask;
            *idx = ii;
            return &file_table[ii];
        }
    }
    return NULL;
}

static FIL * file_table_free( int idx ) {
    const int mask = ( 1 << idx );
    file_table_bits &= ~mask;
    return &file_table[idx];
}

static FIL * file_table_get( int idx ) {
    return &file_table[idx];
}

void _exit( __attribute__((unused)) int status ) {
    // TODO : Return to everdrive/EZF
    __asm__ volatile("swi #0x00\n"); /* Soft reset */
    /* __asm__ volatile("swi #0x26\n"); */ /* Hard reset */
    __builtin_unreachable();
}

char * _sbrk( int incr ) {
    extern char __ewram_end;
    extern char __ewram_top;
    static char * heap_end = &__ewram_end;

    if ( ( uintptr_t ) ( heap_end + incr ) > ( uintptr_t ) &__ewram_top ) {
        errno = ENOMEM;
        return ( char * ) -1;
    }

    char * const prev_heap_end = heap_end;
    heap_end += incr;
    return prev_heap_end;
}

int _getpid( void ) {
    return 0;
}

static int _gba_nosys() {
    errno = ENOSYS;
    return -1;
}

int _close( int file ) {
    if ( !_disk_status ) {
        errno = EIO;
        return -1;
    }
    FIL * const fp = file_table_free( file );
    if ( f_close( fp ) ) {
        errno = EIO;
        return -1;
    }

    return 0;
}

int _execve( char * name, char ** argv, char ** env ) __attribute__((alias("_gba_nosys")));

int _fork( void ) __attribute__((alias("_gba_nosys")));

int _fstat( int __fd, struct stat * __sbuf ) __attribute__((alias("_gba_nosys")));

int _isatty( int file ) __attribute__((alias("_gba_nosys")));

int _kill( int pid, int sig ) __attribute__((alias("_gba_nosys")));

int _link( char * old, char * next ) __attribute__((alias("_gba_nosys")));

int _lseek( int file, int ptr, int dir ) {
    if ( !_disk_status ) {
        errno = EIO;
        return -1;
    }

    FIL * const fp = file_table_get( file );

    FSIZE_t cur = f_tell( fp );
    switch ( dir ) {
        case SEEK_SET:
            cur = ptr;
            break;
        case SEEK_CUR:
            cur += ptr;
            break;
        case SEEK_END:
            cur = f_size( fp ) + ptr;
            break;
        default:
            return EINVAL;
    }
    if ( f_lseek( fp, cur ) ) {
        errno = EIO;
        return -1;
    }

    return ( int ) cur;
}

int _open( const char * name, int flags, int mode ) {
    if ( !_disk_status ) {
        errno = EIO;
        return -1;
    }

    int idx;
    FIL * const fp = file_table_alloc( &idx );
    if ( !fp ) {
        errno = ENFILE;
        return -1;
    }

    flags += 1;

    int fatFsFlags = 0;
    if ( flags & _FREAD ) fatFsFlags |= FA_READ;
    if ( flags & _FWRITE ) fatFsFlags |= FA_WRITE;
    if ( flags & _FAPPEND ) fatFsFlags |= FA_OPEN_APPEND;
    if ( ( flags & ( _FTRUNC | _FCREAT ) ) == ( _FTRUNC | _FCREAT ) ) fatFsFlags |= FA_CREATE_ALWAYS;
    if ( flags & _FEXCL ) fatFsFlags |= FA_CREATE_NEW;

    const FRESULT result = f_open( fp, name, fatFsFlags );
    if ( result ) {
        file_table_free( idx );
        errno = EIO;
        return -1;
    }

    return idx;
}

int _read( int file, char * ptr, int len ) {
    if ( !_disk_status ) {
        return EIO;
    }

    FIL * const fp = file_table_get( file );

    UINT outLen;
    if ( f_read( fp, ptr, len, &outLen ) ) {
        return 0;
    }
    return ( int ) outLen;
}

int _stat( char * file, struct stat * st ) __attribute__((alias("_gba_nosys")));

int _times( void * buf ) __attribute__((alias("_gba_nosys")));

int _unlink( char * name ) __attribute__((alias("_gba_nosys")));

int _wait( int * status ) __attribute__((alias("_gba_nosys")));

int _write( int file, char * ptr, int len ) {
    if ( !_disk_status ) {
        return EIO;
    }

    FIL * const fp = file_table_get( file );

    UINT outLen;
    if ( f_write( fp, ptr, len, &outLen ) ) {
        return 0;
    }
    return ( int ) outLen;
}
