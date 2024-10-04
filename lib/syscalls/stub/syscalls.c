/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

/* Stubs based on https://sourceware.org/newlib/libc.html */

#include <errno.h>
#include <sys/stat.h>

static int stub(void) {
    errno = ENOSYS;
    return -1;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattribute-alias"

int _getpid(void) __attribute__((alias("stub")));

int _kill(int pid, int sig) __attribute__((alias("stub")));

int _close_r(struct _reent *ptr, int fd) __attribute__((alias("stub")));

int _fstat_r(struct _reent *ptr, int fd, struct stat *pstat) __attribute__((alias("stub")));

int _isatty_r(struct _reent *ptr, int fd) __attribute__((alias("stub")));

off_t _lseek_r(struct _reent *ptr, int fd, off_t pos, int whence) __attribute__((alias("stub")));

int _read_r(struct _reent *ptr, int fd, void* buf, size_t cnt) __attribute__((alias("stub")));

int _write_r(struct _reent *ptr, int fd, const void* buf, size_t cnt) __attribute__((alias("stub")));

#pragma GCC diagnostic pop
