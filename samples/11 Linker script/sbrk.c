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
