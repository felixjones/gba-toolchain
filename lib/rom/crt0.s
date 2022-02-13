/*
===============================================================================

 Runtime for GBA ROM

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

    .section .crt0, "ax"
    .align 2
    .arm
    .global _start
_start:
    // Jump past header to start of ROM
    b       .Lrom_start

    // GBA header
    .fill   156, 1, 0 // Logo data
    .fill   12, 1, 0 // ROM title
    .byte   0x00, 0x00, 0x00, 0x00 // ROM code in UTTD format (U = unique code, TT = short title, D = destination/language)
    .byte   0x00, 0x00 // Developer ID
    .byte   0x96 // Fixed value
    .byte   0x00 // Target device code (0 for GBA models)
    .byte   0x00 // Debug flags
    .byte   0x00, 0x00, 0x00 // Unused 3 bytes
.Lzero_word:
    .word   0x00000000 // Unused 4 bytes (runtime assumes zero filled)
    .byte   0x00 // Software version
    .byte   0x00 // Compliment check
    .short  0x0000 // Reserved area (should be zero filled)

    // __ROM_START_PADDING__ bytes can be inserted before rom_start
    // This may be used for save strings
#ifdef __ROM_START_PADDING__
    .fill   __ROM_START_PADDING__, 1, 0
    .align  2
#endif

    // ROM (ARM) execution entry point
    .arm
.Lrom_start:
    // r3 set to REG_BASE
    mov     r3, #0x4000000

    // Disable IME by setting lowest bit to zero (using REG_BASE)
    str     r3, [r3, #0x208]

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

    // ROM (thumb) execution entry point
    .thumb
.Lthumb_start:
    // CpuSet fill bss
    ldr     r0, =.Lzero_word
    ldr     r1, =__bss_start
    ldr     r2, =__bss_cpuset_fill
    swi     #0xb

    // CpuSet fill sbss
    ldr     r1, =__sbss_start
    ldr     r2, =__sbss_cpuset_fill
    swi     #0xb

    // CpuSet copy ewram
    ldr     r0, =__ewram_cpuset
    ldm     r0, {r0-r2}
    swi     #0xb

    // CpuSet copy iwram
    ldr     r0, =__iwram_cpuset
    ldm     r0, {r0-r2}
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
    push    {r0}
    bl      .Lbx_r2
    pop     {r0}

    // Fallthrough to _exit
    .thumb_func
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

    .section .crt0._getpid, "ax", %progbits
    .thumb_func
    .global _getpid
_getpid:
    mov     r0, #0
    // Fallthrough to __sync_synchronize

    .section .crt0.__sync_synchronize, "ax", %progbits
    .thumb_func
    .global __sync_synchronize
__sync_synchronize:
    bx      lr
