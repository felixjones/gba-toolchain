/*
===============================================================================

 _sbrk

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <errno.h>
#include <stdint.h>

#undef errno
extern int errno;
#if defined(__DEVKITARM__)
int errno __attribute__((section(".sbss.errno"))); // devkitARM lacks errno
#endif

#define EWRAM_TOP 0x2040000

char* _sbrk(int incr) {
    extern char __ewram_end;
    static char * heap_end = &__ewram_end;

    if ((uintptr_t) (heap_end + incr) >= EWRAM_TOP) {
        errno = ENOMEM;
        return (char*) -1;
    }

    char* prev_heap_end = heap_end;
    heap_end += incr;
    return prev_heap_end;
}

#if defined(__DEVKITARM__)
// devkitARM uses _sbrk_r
char* _sbrk_r(__attribute__((unused)) void* reent, int incr) {
    return _sbrk(incr);
}
#endif
