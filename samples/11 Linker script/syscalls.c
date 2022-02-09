/*
===============================================================================

 Minimal syscalls for GBA

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>

#include <sys/stat.h>
#include <errno.h>

#undef errno
extern int errno;

char * _sbrk( int incr ) {
    extern char __ewram_base;
    extern char __ewram_top;
    static char * heap_end = &__ewram_base;

    if ( ( uintptr_t ) ( heap_end + incr ) > ( uintptr_t ) &__ewram_top ) {
        errno = ENOMEM;
        return ( char * ) -1;
    }

    char * const prev_heap_end = heap_end;
    heap_end += incr;
    return prev_heap_end;
}

void _exit(__attribute__((unused)) int status) {
    SoftReset();
    __builtin_unreachable();
}

pid_t _getpid() {
    return 0;
}

static int _gba_nosys() {
    errno = ENOSYS;
    return -1;
}

int _kill( int pid, int sig ) __attribute__((alias("_gba_nosys")));

int _write( int file, char * ptr, int len ) __attribute__((alias("_gba_nosys")));

int _close( int file ) __attribute__((alias("_gba_nosys")));

int _fstat( int __fd, struct stat * __sbuf ) __attribute__((alias("_gba_nosys")));

int _isatty( int file ) __attribute__((alias("_gba_nosys")));

int _lseek( int file, int ptr, int dir ) __attribute__((alias("_gba_nosys")));

int _read( int file, char * ptr, int len ) __attribute__((alias("_gba_nosys")));
