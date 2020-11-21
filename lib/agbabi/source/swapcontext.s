@--------------------------------------------------------------------------------
@ swapcontext.s
@--------------------------------------------------------------------------------
@ Sort of based on https://www.man7.org/linux/man-pages/man3/swapcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_SP     60
#define MCONTEXT_ARM_LR     64

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_swapcontext
    .type   __agbabi_swapcontext STT_FUNC
__agbabi_swapcontext:
    push    {r0-r1, lr}
    .extern __agbabi_getcontext
    bl      __agbabi_getcontext
    pop     {r0-r1, lr}

    str     sp, [r0, #MCONTEXT_ARM_SP]
    str     lr, [r0, #MCONTEXT_ARM_LR]

    mov     r0, r1
    .extern __agbabi_setcontext
    b       __agbabi_setcontext
