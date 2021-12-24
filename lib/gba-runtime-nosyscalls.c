/*
===============================================================================

 _sbrk and stub syscalls for GBA ROM and Multiboot

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <sys/stat.h>
#include <errno.h>

#undef errno
extern int errno;

char * __env[1] = { 0 };
char ** environ = __env;

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

static int _gba_nosys() {
    errno = ENOSYS;
    return -1;
}

int _close( int file ) __attribute__((alias("_gba_nosys")));

int _execve( char * name, char ** argv, char ** env ) __attribute__((alias("_gba_nosys")));

int _fork( void ) __attribute__((alias("_gba_nosys")));

int _fstat( int __fd, struct stat * __sbuf ) __attribute__((alias("_gba_nosys")));

int _isatty( int file ) __attribute__((alias("_gba_nosys")));

int _kill( int pid, int sig ) __attribute__((alias("_gba_nosys")));

int _link( char * old, char * next ) __attribute__((alias("_gba_nosys")));

int _lseek( int file, int ptr, int dir ) __attribute__((alias("_gba_nosys")));

int _open( const char * name, int flags, int mode ) __attribute__((alias("_gba_nosys")));

int _read( int file, char * ptr, int len ) __attribute__((alias("_gba_nosys")));

int _stat( char * file, struct stat * st ) __attribute__((alias("_gba_nosys")));

int _times( void * buf ) __attribute__((alias("_gba_nosys")));

int _unlink( char * name ) __attribute__((alias("_gba_nosys")));

int _wait( int * status ) __attribute__((alias("_gba_nosys")));

int _write( int file, char * ptr, int len ) __attribute__((alias("_gba_nosys")));
