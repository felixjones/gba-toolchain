/*
===============================================================================

 Runtime for GBA Multiboot

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

    .section .crt0, "ax"
    .align 2
    .arm
.Lrom_start:
#ifndef __NO_ROM_COPY__
    // If started as ROM, copy EWRAM before starting as Multiboot
    b       .Lewram_copy
#else
    b       .Lrom_start // Not compatible with ROM, so safely infinite loop
#endif

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

    // Multiboot (ARM) execution entry point
    .arm
    .global _start
_start:
    // Jump past Multiboot header to EWRAM start
    b       .Lewram_start

    .byte   0x00 // Boot method (set by BIOS)
    .byte   0x00 // Slave ID number (set by BIOS)
    .fill   26, 1, 0x00 // Unused 26 bytes

    .arm
.Lewram_start:
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

    // CpuSet fill bss
    ldr     r0, =.Lzero_word
    ldr     r1, =__bss_start
    ldr     r2, =__bss_cpuset_fill
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

    // Store result of main
    push    {r0}

    // Finalizers
    .extern __libc_fini_array
    ldr     r2, =__libc_fini_array
    bl      .Lbx_r2

    // Restore result of main
    pop     {r0}

    // Fallthrough to _exit
    .thumb
    .global _exit
_exit:
    ldr     r2, =.Lewram_start
    // Fallthrough to branch-link

    // For branch-link
    .thumb
.Lbx_r2:
    bx      r2

// Don't need to copy EWRAM if there's no ROM compatibility
#ifndef __NO_ROM_COPY__
    .arm
.Lewram_copy:
    // CpuSet copy ewram data
    ldr     r0, =__ewram_lma
    ldr     r1, =__ewram_start
    ldr     r2, =__ewram_cpuset_copy
    swi     #0xb
    b       .Lewram_start
#endif

    // Reference symbols from gba-syscalls.c to prevent removal
    .global _sbrk
    .global _kill

    // Placed in own section to allow gc-section removal
    .section .crt0._getpid, "ax", %progbits
    .thumb
    .global _getpid
_getpid:
    mov     r0, #0
    // Fallthrough to __sync_synchronize

    .section .crt0.__sync_synchronize, "ax", %progbits
    .global __sync_synchronize
__sync_synchronize:
    bx      lr
