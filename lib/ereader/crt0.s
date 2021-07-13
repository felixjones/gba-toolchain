@----------------------------------------
@ crt0.s
@----------------------------------------

    .section .crt0, "ax"
    .align 2
    .arm
    .global _start
_start:
    @ Immediately jump past header data to e-reader code
    b       .Lereader_start

    @ Header data
.Lzero_word:
    .fill   4, 1, 0x00  @ Unused byte x4
    .word   0x02000000

.Lereader_start:
    @ Enter thumb mode (bit 0 is set to 1)
    adr     r0, .Lthumb_start + 1
    bx      r0

    .thumb
.Lthumb_start:
    @ Reset memory regions
    mov     r0, #0xfe
    swi     #0x1

    @ CpuSet copy iwram
    ldr	    r0, =__iwram_lma
    ldr	    r1, =__iwram_start
    ldr	    r2, =__iwram_cpuset_copy
    swi     #0xb

    @ CpuSet copy data
    ldr	    r0, =__data_lma
    ldr	    r1, =__data_start
    ldr	    r2, =__data_cpuset_copy
    swi     #0xb

    @ Store e-reader return address
    push    {lr}

    @ __libc_init_array
    ldr     r2, =__libc_init_array
    bl      .Lbx_r2

    @ main
    mov     r0, #0  @ argc
    mov     r1, #0  @ argv
    ldr     r2, =main
    bl      .Lbx_r2

    @ Store result of main
    push    {r0}

    @ __libc_fini_array
    ldr     r2, =__libc_fini_array
    bl      .Lbx_r2

    @ Restore result of main
    pop     {r0}

    .global _exit
_exit:
    @ Restore e-reader return address
    pop     {r2}
    @ fallthrough

.Lbx_r2:
    bx      r2

    @ Prevent gba-syscalls from being removed
    .global _gba_syscalls_keep
