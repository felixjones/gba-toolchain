#pragma once

#ifdef __WONDERFUL__
struct _reent;
#else
#   include <reent.h>
#endif

#include <sys/stat.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

#define STD_IN (0)
#define STD_OUT (1)
#define STD_ERR (2)

struct statvfs {
    unsigned long f_bsize;
    unsigned long f_frsize;
    fsblkcnt_t f_blocks;
    fsblkcnt_t f_bfree;
    fsblkcnt_t f_bavail;
    fsfilcnt_t f_files;
    fsfilcnt_t f_ffree;
    fsfilcnt_t f_favail;
    unsigned long f_fsid;
    unsigned long f_flag;
    unsigned long f_namemax;
};

typedef struct {
    int device;
    void* dirStruct;
} DIR_ITER;

typedef struct {
    const char* name;
    int structSize;

    int (*open_r)(struct _reent* r, void* fileStruct, const char* path, int flags, int mode);

    int (*close_r)(struct _reent* r, int fd);

    ssize_t (*write_r)(struct _reent* r, int fd, const char* ptr, size_t len);

    ssize_t (*read_r)(struct _reent* r, int fd, char* ptr, size_t len);

    off_t (*seek_r)(struct _reent* r, int fd, off_t pos, int dir);

    int (*fstat_r)(struct _reent* r, int fd, struct stat* st);

    int (*stat_r)(struct _reent* r, const char* file, struct stat* st);

    int (*link_r)(struct _reent* r, const char* existing, const char* newLink);

    int (*unlink_r)(struct _reent* r, const char* name);

    int (*chdir_r)(struct _reent* r, const char* name);

    int (*rename_r)(struct _reent* r, const char* oldName, const char* newName);

    int (*mkdir_r)(struct _reent* r, const char* path, int mode);

    int dirStateSize;

    DIR_ITER* (*diropen_r)(struct _reent* r, DIR_ITER* dirState, const char* path);

    int (*dirreset_r)(struct _reent* r, DIR_ITER* dirState);

    int (*dirnext_r)(struct _reent* r, DIR_ITER* dirState, char* filename, struct stat* filestat);

    int (*dirclose_r)(struct _reent* r, DIR_ITER* dirState);

    int (*statvfs_r)(struct _reent* r, const char* path, struct statvfs* buf);

    int (*ftruncate_r)(struct _reent* r, int fd, off_t len);

    int (*fsync_r)(struct _reent* r, int fd);

    void* deviceData;

    int (*chmod_r)(struct _reent* r, const char* path, mode_t mode);

    int (*fchmod_r)(struct _reent* r, int fd, mode_t mode);
} devoptab_t;

extern const devoptab_t* devoptab_list[];

#ifdef __cplusplus
} // extern "C"
#endif
