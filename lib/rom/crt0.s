    .align 2
    .section .crt0, "ax"

    .arm
    .global __start
__start:
    b       _start

    .global _start
_start:
    b       _start
