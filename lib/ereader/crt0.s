/*
===============================================================================

 Runtime for GBA e-reader

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

    .section .crt0, "ax"
    .align 2
    .arm
    .global _start
_start:
    // Jump to ARM entry point
    b       .Larm_start
.Lzero_word:
    .word   0x00000000

    // This word is destroyed by e-reader
    .word   0x00000000

    // EWRAM (arm) execution entry point
    .arm
.Larm_start:
    // Switch to IRQ mode (0x12)
    mov     r0, #0x12
    msr     cpsr, r0
    ldr     sp, =__sp_irq // Set IRQ stack pointer

    // Switch to user mode (0x1f)
    mov     r0, #0x1f
    msr     cpsr, r0
    ldr     sp, =__sp_usr // Set user stack pointer

    // Enter thumb mode (bit 0 is set to 1)
    adr     r0, .Lthumb_start + 1
    bx      r0

    // EWRAM (thumb) execution entry point
    .thumb
.Lthumb_start:
    // Reset memory regions (includes bss)
    mov     r0, #0xfe
    swi     #0x1

    // CpuSet copy ewram data
    ldr     r0, =__ewram_data_lma
    ldr     r1, =__ewram_data_start
    ldr     r2, =__ewram_data_cpuset_copy
    swi     #0xb

    // CpuSet copy iwram
    ldr     r0, =__iwram_lma
    ldr     r1, =__iwram_start
    ldr     r2, =__iwram_cpuset_copy
    swi     #0xb

    // CpuSet copy data
    ldr     r0, =__data_lma
    ldr     r1, =__data_start
    ldr     r2, =__data_cpuset_copy
    swi     #0xb

    // Initializers
    .extern __libc_init_array
    ldr     r2, =__libc_init_array
    bl      .Lbx_r2

    // Main
    mov     r0, #0 // argc
    mov     r1, #0 // argv
    .extern main
    ldr     r2, =main
    bl      .Lbx_r2

    // Finalizers
    .extern __libc_fini_array
    ldr     r2, =__libc_fini_array
    bl      .Lbx_r2

    // Fallthrough to _exit
    .thumb
    .global _exit
_exit:
    swi     #0x00 // Soft reset

    // For branch-link
    .thumb
.Lbx_r2:
    bx      r2

    // Reference symbols from gba-syscalls.c to prevent removal
    .global _sbrk
    .global _kill

    // Placed in own section to allow gc-section removal
    .section .crt0._getpid, "ax", %progbits
    .thumb
    .global _getpid
_getpid:
    mov     r0, #0
    bx      lr
