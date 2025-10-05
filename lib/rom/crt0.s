@===============================================================================
@
@ Copyright (C) 2021-2025 gba-toolchain contributors
@ For conditions of distribution and use, see copyright notice in LICENSE.md
@
@===============================================================================

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

    @ Using r4-r5 to avoid pushing r0-r3
    @ init immediately follows preinit so we can join these arrays
    ldr     r4, =__preinit_array_start
    ldr     r5, =__init_array_end
1:  cmp     r4, r5
    beq     2f
    ldr     r0, [r4]
    add     r4, r4, #4
    bl      _CALL_R0_VENEER
    b       1b
2:

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
    bl      __call_exitprocs

    ldr     r4, =__fini_array_end
    ldr     r5, =__fini_array_start
3:  cmp     r4, r5
    beq     4f
    sub     r4, r4, #4
    ldr     r0, [r4]
    bl      _CALL_R0_VENEER
    b       3b
4:

    @ Fallthrough

    .thumb
    .global _Exit
_Exit:
    ldr     r1, =#0x4000208
    str     r1, [r1] @ Disable REG_IME (lowest bit = 0)

    @ SoftReset
    swi     #0x0

    .thumb
_CALL_R0_VENEER:
    bx      r0
    .size   _CALL_R0_VENEER, .-_CALL_R0_VENEER
