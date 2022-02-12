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

#define EWRAM_TOP 0x2040000

char* __env[1] = { 0 };
char** environ = __env;

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

static int _gba_nosys() {
    errno = ENOSYS;
    return -1;
}

int _close(int file) __attribute__((alias("_gba_nosys")));

int _execve(char* __restrict__ name, char** __restrict__ argv, char** __restrict__ env) __attribute__((alias("_gba_nosys")));

int _fork(void) __attribute__((alias("_gba_nosys")));

int _fstat(int __fd, struct stat* __sbuf) __attribute__((alias("_gba_nosys")));

int _isatty(int file) __attribute__((alias("_gba_nosys")));

int _kill(int pid, int sig) __attribute__((alias("_gba_nosys")));

int _link(char* __restrict__ old, char* __restrict__ next) __attribute__((alias("_gba_nosys")));

int _lseek(int file, int ptr, int dir) __attribute__((alias("_gba_nosys")));

int _open(const char* __restrict__ name, int flags, int mode) __attribute__((alias("_gba_nosys")));

int _read(int file, char* ptr, int len) __attribute__((alias("_gba_nosys")));

int _stat(char* __restrict__ file, struct stat* __restrict__ st) __attribute__((alias("_gba_nosys")));

int _times(void* buf) __attribute__((alias("_gba_nosys")));

int _unlink(char* name) __attribute__((alias("_gba_nosys")));

int _wait(int* status) __attribute__((alias("_gba_nosys")));

int _write(int file, char* ptr, int len) __attribute__((alias("_gba_nosys")));
