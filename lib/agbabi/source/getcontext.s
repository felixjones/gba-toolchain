@--------------------------------------------------------------------------------
@ getcontext.s
@--------------------------------------------------------------------------------
@ Implementation of https://www.man7.org/linux/man-pages/man3/getcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_R4     4
#define MCONTEXT_ARM_PC     48
#define MCONTEXT_ARM_CPSR   52

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_getcontext
    .type   __agbabi_getcontext STT_FUNC
__agbabi_getcontext:
    @ No need to save r0-r3, so we write r4-r12, sp and lr
    add     r1, r0, #MCONTEXT_ARM_R4
    stmia   r1, {r4-r12, sp, lr}

    @ Store lr as return point (useful)
    str     lr, [r0, #MCONTEXT_ARM_PC]

    @ Store cpsr
    mrs     r1, cpsr
    str     r1, [r0, #MCONTEXT_ARM_CPSR]

    @ Return 0
    mov     r0, #0
    bx      lr
