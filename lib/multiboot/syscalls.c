/* Stubs based on https://sourceware.org/newlib/libc.html */

#include <errno.h>
#include <sys/stat.h>

#undef errno
extern int errno;

static int stub(void) {
    errno = ENOSYS;
    return -1;
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "bugprone-reserved-identifier"
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattribute-alias"

int _close(int file) __attribute__((alias("stub")));

int _fstat(int file, struct stat *st) __attribute__((alias("stub")));

int _getpid(void) __attribute__((alias("stub")));

int _isatty(int file) __attribute__((alias("stub")));

int _kill(int pid, int sig) __attribute__((alias("stub")));

int _lseek(int file, int ptr, int dir) __attribute__((alias("stub")));

int _read(int file, char *ptr, int len) __attribute__((alias("stub")));

int _write(int file, char *ptr, int len) __attribute__((alias("stub")));

#pragma GCC diagnostic pop
#pragma clang diagnostic pop
