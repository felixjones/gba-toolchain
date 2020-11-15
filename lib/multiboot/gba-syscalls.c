#include <sys/stat.h>
#include <errno.h>

#undef errno
extern int errno;

char * __env[1] = { 0 };
char ** environ = __env;

void _exit(__attribute__((unused)) int status) {
    void __ewram_start(void);

    __ewram_start();
    __builtin_unreachable();
}

int _close(int file) {
    return -1;
}

int _execve(char * name, char ** argv, char ** env) {
    errno = ENOMEM;
    return -1;
}

int _fork(void) {
    errno = EAGAIN;
    return -1;
}

int _fstat(int __fd, struct stat * __sbuf) {
    __sbuf->st_mode = S_IFCHR;
    return 0;
}

int _getpid(void) {
    return 1;
}

int _isatty(int file) {
    return 1;
}

int _kill(int pid, int sig) {
    errno = EINVAL;
    return -1;
}

int _link(char * old, char * next) {
    errno = EMLINK;
    return -1;
}

int _lseek(int file, int ptr, int dir) {
    return 0;
}

int _open(const char * name, int flags, int mode) {
    return -1;
}

int _read(int file, char * ptr, int len) {
    return 0;
}

char * _sbrk(int incr) {
    extern char __ewram_top; /* Defined by the linker */
    static char * heap_end = &__ewram_top;

    char * const prev_heap_end = heap_end;
    heap_end += incr;
    return prev_heap_end;
}

int _stat(char * file, struct stat * st) {
    st->st_mode = S_IFCHR;
    return 0;
}

int _times(void * buf) {
    return -1;
}

int _unlink(char * name) {
    errno = ENOENT;
    return -1;
}

int _wait(int * status) {
    errno = ECHILD;
    return -1;
}

int _write(int file, char * ptr, int len) {
    return 0;
}
