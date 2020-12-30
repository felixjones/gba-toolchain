@--------------------------------------------------------------------------------
@ setcontext.s
@--------------------------------------------------------------------------------
@ Sort of based on https://www.man7.org/linux/man-pages/man3/setcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_R0     12

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    
    .func   __agbabi_setcontext
    .global __agbabi_setcontext
    .type   __agbabi_setcontext STT_FUNC
__agbabi_setcontext:
    @ Restore r0-r11, sp, lr
    add     lr, r0, #MCONTEXT_ARM_R0
    ldmia   lr, {r0-r11, sp, lr}
    bx      lr
    .endfunc

    .func   __agbabi_ctx_start
    .global __agbabi_ctx_start
    .type   __agbabi_ctx_start STT_FUNC
__agbabi_ctx_start:
    .fnstart
    push    {r5}
    mov     lr, pc
    bx      r4
    pop     {r5}
    movs    r0, r5
    bne     __agbabi_setcontext
    .extern _exit
    ldr     r1, =_exit
    bx      r1
    .fnend
    .endfunc
