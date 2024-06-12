/*
===============================================================================

 Copyright (C) 2021-2024 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <sys/iosupport.h>

#include <ctype.h>
#include <errno.h>
#include <stdio.h>

#ifdef __WONDERFUL__
#   define _REENT ((struct _reent*) NULL)
#endif

#define STD_MAX (3)

const devoptab_t* devoptab_list[STD_MAX];

static int unimplemented(void) {
    errno = ENOSYS;
    return -1;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattribute-alias"

int _isatty(int fd) __attribute__((alias("unimplemented")));
off_t _lseek(int fd, off_t offset, int whence) __attribute__((alias("unimplemented")));
int _fstat(int fd, struct stat* statbuf) __attribute__((alias("unimplemented")));

#pragma GCC diagnostic pop

int _open(void* fileStruct, const char* path, const int flags, const int mode) {
    for (int i = 0; i < STD_MAX; ++i) {
        const int res = devoptab_list[i]->open_r(_REENT, fileStruct, path, flags, mode);
        if (res == 0) {
            return res;
        }
    }
    return unimplemented();
}

int _close(const int fd) {
    if (fd < STD_MAX) {
        return devoptab_list[fd]->close_r(_REENT, fd);
    }
    return unimplemented();
}

ssize_t _write(const int fd, const char* ptr, const size_t len) {
    if (fd < STD_MAX) {
        // Buffer big enough 2x two-digit parameters. eg: ESC[##;##H
        #define ESCAPE_BUFFER_SIZE (8)

        static char escape_buffer[ESCAPE_BUFFER_SIZE];
        static size_t escape_buffer_index = 0;

        size_t i;
        for (i = 0; i < len; ++i) {
            const char c = ptr[i];

            if (escape_buffer_index == ESCAPE_BUFFER_SIZE) {
                devoptab_list[fd]->write_r(_REENT, fd, escape_buffer, escape_buffer_index); // Buffer full: Flush
                escape_buffer_index = 0;
            }

            if ((escape_buffer_index == 0 && c == '\033') || (escape_buffer_index == 1 && c == '[') || isdigit(c) || c == ';') {
                escape_buffer[escape_buffer_index++] = c; // Build buffer
                continue;
            }

            if (escape_buffer_index) {
                escape_buffer[escape_buffer_index++] = c; // Unexpected: assume end of escape
                devoptab_list[fd]->write_r(_REENT, fd, escape_buffer, escape_buffer_index);
                escape_buffer_index = 0;
            } else {
                break;
            }
        }

        if (i == len) {
            return len;
        }

        return devoptab_list[fd]->write_r(_REENT, fd, ptr + i, len - i);
    }

    return unimplemented();
}

ssize_t _read(const int fd, char* ptr, const size_t len) {
    if (fd < STD_MAX) {
        return devoptab_list[fd]->read_r(_REENT, fd, ptr, len);
    }
    return unimplemented();
}
