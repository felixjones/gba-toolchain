/*
===============================================================================

 Runtime for GBA ROM

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

    .align 2
    .section .crt0, "ax"

    // ROM entry point
    .arm
    .global __start
__start:
    // Jump past header to start of ROM
    b       _start

    // Include header data (192 bytes)
#include "../gba-header.s"

    // __ROM_START_PADDING__ bytes can be inserted before rom_start
    // This may be used for save strings
#ifdef __ROM_START_PADDING__
    .fill   __ROM_START_PADDING__, 1, 0
    .align  2
#endif

    // _start
    .arm
    .global _start
_start:
    // Disable REG_IME by setting lowest bit to zero (using lowest bit of REG_IME)
    mov     r0, #0x4000000
    str     r0, [r0, #0x208]

    // Enter thumb mode (bit 0 is set to 1)
    adr     r0, .Lthumb_start + 1
    bx      r0

    .thumb_func
.Lthumb_start:
    // CpuSet clear bss (iwram)
    ldr     r0, =.Lzero_word
    ldr     r1, =__bss_start
    ldr     r2, =__bss_cpuset_fill
    swi     #0xb

    // CpuSet clear sbss (ewram)
    ldr     r0, =.Lzero_word
    ldr     r1, =__sbss_start
    ldr     r2, =__sbss_cpuset_fill
    swi     #0xb

    // CpuSet copy ewram sections
    ldr     r0, =__ewram_cpuset
    ldm     r0, {r0-r2}
    swi     #0xb

    // CpuSet copy iwram sections
    ldr     r0, =__iwram_cpuset
    ldm     r0, {r0-r2}
    swi     #0xb

    // preinit_array (r0-r3 are clobbered, r4 is used for .Lbx_r4, so use r5-r6)
    ldr     r5, =__preinit_array_start
    ldr     r6, =__preinit_array_end
    bl      .Lcall_array

    // init_array (r0-r3 are clobbered, r4 is used for .Lbx_r4, so use r5-r6)
    ldr     r5, =__init_array_start
    ldr     r6, =__init_array_end
    bl      .Lcall_array

    // main
    mov     r0, #0 // argc
    mov     r1, #0 // argv (NULL)
    ldr     r4, =main
    bl      .Lbx_r4

#ifndef __NO_FINI__
    push    {r0, r1} // Push exit code (r1 for alignment)

    // Disable REG_IME by setting lowest bit to zero (using lowest bit of REG_IME)
    ldr     r1, =#0x4000208
    str     r1, [r1]

    // fini_array
    ldr     r5, =__fini_array_start
    ldr     r6, =__fini_array_end
    bl      .Lrcall_array

    pop     {r0, r1} // Pop exit code (r1 for alignment)
#endif

    b       exit

    .thumb_func
.Lpop_r3_bx_r4:
    pop     {r3-r4}
    // Fallthrough to .Lbx_r4

    .thumb_func
.Lbx_r4:
    bx      r4

    // call_array (r4 is used for .Lpop_r3_bx_r4, r5-r6 is used for array)
    .thumb_func
.Lcall_array:
    push    {r3, lr} // r3 pushed for alignment
.Lcall_array_loop:
    cmp     r5, r6
    beq     .Lpop_r3_bx_r4
    ldr     r4, [r5]
    add     r5, #4
    bl      .Lbx_r4
    b       .Lcall_array_loop

#ifndef __NO_FINI__
    // rcall_array (r4 is used for .Lpop_r3_bx_r4, r5-r6 is used for array)
    .thumb_func
.Lrcall_array:
    push    {r3, lr} // r3 pushed for alignment
.Lrcall_array_loop:
    cmp     r5, r6
    beq     .Lpop_r3_bx_r4
    sub     r6, #4
    ldr     r4, [r6]
    bl      .Lbx_r4
    b       .Lrcall_array_loop
#endif

    // exit
    .thumb_func
    .global exit
exit:
#ifndef __NO_FINI__
    push    {r0-r1} // Push exit code (r1 for alignment)

    // Disable REG_IME by setting lowest bit to zero (using lowest bit of REG_IME)
    ldr     r1, =#0x4000208
    str     r1, [r1]

    mov     r1, #0 // NULL
    ldr     r4, =__call_exitprocs
    bl      .Lbx_r4
    pop     {r0, r1} // Pop exit code (r1 for alignment)
#endif
    // Fallthrough to _exit

    // _exit
    .thumb_func
    .global _exit
_exit:
    // Disable REG_IME by setting lowest bit to zero (using lowest bit of REG_IME)
    ldr     r0, =#0x4000208
    str     r0, [r0]

    swi     #0x00 // Soft reset

    // Reference _sbrk, _getpid to prevent removal
    .global _sbrk
    .global _getpid

#ifndef __NO_FINI__
    // Reference __register_exitproc to enable static destructors atexit
    .global __register_exitproc
#endif

    .thumb_func
    .global __sync_synchronize
__sync_synchronize:
    bx      lr
