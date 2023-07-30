@===============================================================================
@
@ Copyright (C) 2021-2023 gba-toolchain contributors
@ For conditions of distribution and use, see copyright notice in LICENSE.md
@
@===============================================================================

    .section .crt0.preheader, "ax"
    .arm
    .align 2
    .global __rom_start
__rom_start:
    b       __start

    .arm
    .align 2
    .global __mb_header

    .section .crt0.postheader, "ax"
    .arm
    .align 2
    .global __start
__start:
    .global _start
    b       _start

    .global __mb_info
__mb_info:
    @ Boot Mode (overridden)
    .byte   0x00

    @ Client ID (overridden)
    .byte   0x00

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

    @ CpuFastSet copy iwram
    ldr     r0, =__iwram_lma
    ldr     r1, =__iwram_start
    ldr     r2, =__iwram_swi0c
    swi     #0xc

    @ Using r4-r5 to avoid pushing r0-r3
    @ init immediately follows preinit so we can join these arrays
    ldr     r4, =__preinit_array_start
    ldr     r5, =__init_array_end
    bl      __array_call

    @ argc, argv
    mov     r0, #0
    mov     r1, #0
    bl      main
    @ Fallthrough

    .thumb
    .global exit
exit:
    ldr     r1, =#0x4000208
    str     r1, [r1] @ Disable REG_IME (lowest bit = 0)

    mov     r1, #0 @ NULL
    push    {r0} @ Push exit code
    bl      __call_exitprocs
    pop     {r0}

    @ Using r4-r5 to avoid pushing r0-r3
    ldr     r4, =__fini_array_start
    ldr     r5, =__fini_array_end
    bl      __array_call
    @ Fallthrough

    .thumb
    .global _Exit
_Exit:
    ldr     r1, =#0x4000208
    str     r1, [r1] @ Disable REG_IME (lowest bit = 0)

    @ Loop
    b       _start

    .thumb
__array_call:
    push    {lr}
    cmp     r4, r5
    beq     .Larray_skip
.Larray_loop:
    ldm     r4!, {r0}
    bl      .Larray_bx
    cmp     r4, r5
    bne     .Larray_loop
.Larray_skip:
    pop     {r0}
.Larray_bx:
    bx      r0

    @ Reference a symbol from syscalls.c to keep
    .global _getpid
