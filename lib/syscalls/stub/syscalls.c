/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

/* Stubs based on https://sourceware.org/newlib/libc.html */

#include <errno.h>

static int stub(void) {
    errno = ENOSYS;
    return -1;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattribute-alias"

int _getpid(void) __attribute__((alias("stub")));

int _kill(int pid, int sig) __attribute__((alias("stub")));

#pragma GCC diagnostic pop
