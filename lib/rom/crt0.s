    .section .crt0.preheader, "ax"
    .arm
    .align 2
    .global __start
__start:
    b       _start

    .global __cart_header

    .section .crt0.postheader, "ax"
    .arm
    .align 2
    .global _start
_start:
    @ Disable REG_IME (lowest bit = 0)
    mov     r0, #0x4000000
    str     r0, [r0, #0x208]

    @ Switch to thumb mode
    adr     r0, .Lstart + 1
    bx      r0

    .thumb
    .align 1
.Lstart:
    @ CpuFastSet fill sbss
    ldr     r0, =__zero_word
    ldr     r1, =__sbss_start
    ldr     r2, =__sbss_swi0c
    swi     #0xc

    @ CpuFastSet fill bss
    ldr     r0, =__zero_word
    ldr     r1, =__bss_start
    ldr     r2, =__bss_swi0c
    swi     #0xc

    @ CpuFastSet copy ewram
    ldr     r0, =__ewram_lma
    ldr     r1, =__ewram_start
    ldr     r2, =__ewram_swi0c
    swi     #0xc

    @ CpuFastSet copy iwram
    ldr     r0, =__iwram_lma
    ldr     r1, =__iwram_start
    ldr     r2, =__iwram_swi0c
    swi     #0xc

    @ TODO: preinit init stuff

    @ argc, argv
    mov     r0, #0
    mov     r1, #0
    bl      main

    @ TODO: Something something
    b       .Lstart
