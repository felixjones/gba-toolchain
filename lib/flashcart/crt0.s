@----------------------------------------
@ crt0.s
@----------------------------------------

#ifndef __gba_save_id
#define __gba_save_id 0
#endif

    .section .crt0, "ax"
    .align 2
    .arm
    .global _start
_start:
    @ Immediately jump past header data to ROM code
    b	    .Lrom_start

    @ Header data
    .fill   156, 1, 0   @ Nintendo logo     (0x8000004)
    .fill	16, 1, 0    @ Game title
    .byte   0x00, 0x00	@ Developer ID	    (0x80000B0)
    .byte   0x96		@ Fixed value		(0x80000B2)
    .byte   0x00		@ Main unit ID	    (0x80000B3)
    .byte   0x00		@ Device type		(0x80000B4)
    .fill	3, 1, 0x00	@ Unused byte x3

.Lzero_word:
    .fill	4, 1, 0x00	@ Unused byte x4
    .byte	0x00		@ Game version		(0x80000BC)
    .byte	0x00		@ Complement check  (0x80000BD)
    .byte	0x00, 0x00  @ Checksum          (0x80000BE)

#ifdef __gba_save_string
    @ Save type string
    .asciz  __gba_save_string
    .align  2
#endif

.Lrom_start:
    @ r3 set to REG_BASE
    mov     r3, #0x4000000

    @ Set IME to REG_BASE, disables interrupts (May have jumped here from game code)
    str     r3, [r3, #0x208]

    @ Set IRQ stack pointer
    mov	    r0, #0x12
    @ Switch to IRQ mode (0x12)
    msr     cpsr, r0
    ldr	    sp, =__sp_irq

    @ Set user stack pointer
    mov	    r0, #0x1F
    @ Switch to user mode (0x1F)
    msr	    cpsr, r0
    ldr	    sp, =__sp_usr

    @ Enter thumb mode (bit 0 is set to 1)
    adr	    r0, .Lthumb_start + 1
    bx	    r0

    .thumb
.Lthumb_start:
    @ CpuSet copy ewram
    ldr	    r0, =__ewram_lma
    ldr	    r1, =__ewram_start
    ldr	    r2, =__ewram_cpuset_copy
    swi     #0xb

    @ CpuSet copy iwram
    ldr	    r0, =__iwram_lma
    ldr	    r1, =__iwram_start
    ldr	    r2, =__iwram_cpuset_copy
    swi     #0xb

    @ CpuSet fill bss
    ldr	    r0, =.Lzero_word
    ldr	    r1, =__bss_start
    ldr	    r2, =__bss_cpuset_fill
    swi     #0xb

    @ CpuSet copy data
    ldr	    r0, =__data_lma
    ldr	    r1, =__data_start
    ldr	    r2, =__data_cpuset_copy
    swi     #0xb

    nop

    @ Detect mGBA
.Ldetect_mgba:
    ldr     r0, =__mgba_debug_enable
    ldr     r1, .Lmgba_1deacode
    lsr     r2, r1, #16
    strh    r1, [r0]
    ldrh    r1, [r0]
    cmp     r1, r2
    bne 	.Ldetect_everdrive

    mov     r3, #(__gba_save_id)
    ldr     r0, .Lmgba_string_ptr
    push    {r0}
    mov	    r0, #1		@ argc = 1
    mov     r1, sp      @ argv
    b 	    .Llibc_init

.Ldetect_everdrive:
    @ CpuSet copy everdrive
    ldr	    r0, =__everdrive_lma
    ldr	    r1, =__everdrive_start
    ldr	    r2, =__everdrive_cpuset_copy
    swi     #0xb

    ldr	    r2, =_everdrive_bootcheck
    bl	    .Lbx_r2

    cmp     r0, #0
    beq 	.Ldetect_ezflash

    mov     r3, #5
    ldr     r0, .Leverdrive_string_ptr
    push    {r0}
    mov	    r0, #1		@ argc = 1
    mov     r1, sp      @ argv
    b 	    .Llibc_init

.Ldetect_ezflash:
    @ CpuSet copy ezflash
    ldr	    r0, =__ezflash_lma
    ldr	    r1, =__ezflash_start
    ldr	    r2, =__ezflash_cpuset_copy
    swi     #0xb

    ldr	    r2, =_ezflash_bootcheck
    sub     sp, sp, #8  @ Space for storing ROM page and Omega flag
    mov     r1, sp      @ Omega flag
    add     r0, r1, #4  @ ASCII page
    bl	    .Lbx_r2
    pop     {r1, r2}    @ Pop Omega flag and ASCII page

    cmp     r0, #0
    beq 	.Ldetect_none

    mov     r3, #6
    cmp     r1, #1
    beq     .Lezflash_omega
    ldr     r1, .Lezflash_string_ptr
    b       .Lezflash_args
.Lezflash_omega:
    ldr     r1, .Lezflashomega_string_ptr

.Lezflash_args:
    push    {r2}        @ Push ASCII page
    mov     r2, sp      @ r2 = ASCII page address
    push    {r1, r2}    @ Push ARGVs

    mov	    r0, #2		@ argc = 2
    mov     r1, sp      @ argv
    b 	    .Llibc_init

.Ldetect_none:
    mov	    r0, #0		@ argc = 0
    mov     r1, #0      @ argv = 0
    mov     r3, #(__gba_save_id)

.Llibc_init:
    @ Initialise disk routines
    push    {r0, r1}
    movs    r0, r3
    .extern _disk_io_init
    ldr     r2, =_disk_io_init
    bl	    .Lbx_r2
    pop     {r0, r1}

    @ __libc_init_array
    ldr	    r2, =__libc_init_array
    bl	    .Lbx_r2

    @ main
    ldr	    r2, =main
    bl	    .Lbx_r2

    @ Store result of main
    push    {r0}

    @ __libc_fini_array
    ldr     r2, =__libc_fini_array
    bl	    .Lbx_r2

    @ Restore result of main
    pop	    {r0}
    ldr	    r2, =_exit
    @ fallthrough

.Lbx_r2:
    bx      r2

    .align  2
.Lmgba_1deacode:
    .long   0x1deac0de
.Lmgba_string_ptr:
    .long   .Lmgba_string
.Lmgba_string:
    .asciz  "mGBA"

    .align  2
.Leverdrive_string_ptr:
    .long   .Leverdrive_string
.Leverdrive_string:
    .asciz  "everdrive-gba"

    .align  2
.Lezflash_string_ptr:
    .long   .Lezflash_string
.Lezflashomega_string_ptr:
    .long   .Lezflashomega_string
.Lezflash_string:
    .asciz  "ezflash"
.Lezflashomega_string:
    .asciz  "ezflash-omega"

    @ Prevent FatFs functions from being removed
    .global f_open
    .global f_close
    .global f_read
    .global f_write
    .global f_lseek
    .global f_truncate
    .global f_sync
    .global f_forward
    .global f_expand
    .global f_gets
    .global f_putc
    .global f_puts
    .global f_printf
    .global f_tell
    .global f_eof
    .global f_size
    .global f_error
    .global f_opendir
    .global f_closedir
    .global f_readdir
    .global f_findfirst
    .global f_findnext
    .global f_stat
    .global f_unlink
    .global f_rename
    .global f_chmod
    .global f_utime
    .global f_mkdir
    .global f_chdir
    .global f_chdrive
    .global f_getcwd
    .global f_mount
    .global f_mkfs
    .global f_fdisk
    .global f_getfree
    .global f_getlabel
    .global f_setlabel
    .global f_setcp

    @ Prevent Dirent functions from being removed
    .global opendir
    .global readdir
    .global closedir
