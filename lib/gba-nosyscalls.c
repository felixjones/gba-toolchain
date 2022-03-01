/*
===============================================================================

 Empty syscalls

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <sys/stat.h>
#include <sys/times.h>
#include <sys/unistd.h>
#include <errno.h>

#undef errno
extern int errno;
#if defined(__DEVKITARM__)
int errno; // devkitARM lacks errno
#endif

#if defined(__NO_FINI__)
void atexit() {
    return;
}
#endif

pid_t _getpid() {
    return 0;
}

static int _gba_nosys() {
    errno = ENOSYS;
    return -1;
}

int _close(int fd) __attribute__((alias("_gba_nosys")));

int _execve(const char* __restrict__ pathname, char* const __restrict__ argv[], char* const __restrict__ envp[]) __attribute__((alias("_gba_nosys")));

pid_t _fork() __attribute__((alias("_gba_nosys")));

int _fstat(int fd, struct stat* statbuf) __attribute__((alias("_gba_nosys")));

int _kill(pid_t pid, int sig) __attribute__((alias("_gba_nosys")));

int _link(const char* __restrict__ oldpath, const char* __restrict__ newpath) __attribute__((alias("_gba_nosys")));

int _lseek(int fd, off_t offset, int whence) __attribute__((alias("_gba_nosys")));

int _open(const char* __restrict__ pathname, int flags, mode_t mode) __attribute__((alias("_gba_nosys")));

int _read(int fd, void* buf, size_t count) __attribute__((alias("_gba_nosys")));

int _stat(const char* __restrict__ pathname, struct stat* __restrict__ statbuf) __attribute__((alias("_gba_nosys")));

int _times(struct tms* buf) __attribute__((alias("_gba_nosys")));

int _unlink(const char* pathname) __attribute__((alias("_gba_nosys")));

pid_t _wait(int* wstatus) __attribute__((alias("_gba_nosys")));

ssize_t _write(int fd, const void* buf, size_t count) __attribute__((alias("_gba_nosys")));
