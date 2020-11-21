@--------------------------------------------------------------------------------
@ getcontext.s
@--------------------------------------------------------------------------------
@ Sort of based on https://www.man7.org/linux/man-pages/man3/getcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_R0     12
#define MCONTEXT_ARM_R4     28
#define MCONTEXT_ARM_SP     64
#define MCONTEXT_ARM_PC     72
#define MCONTEXT_ARM_CPSR   76

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_getcontext
    .type   __agbabi_getcontext STT_FUNC
__agbabi_getcontext:
    @ No need to save r0-r3 or r12, so we write r4-r11
    add     r1, r0, #MCONTEXT_ARM_R4
    stmia   r1, {r4-r11}

    @ Store sp -> sp, lr -> pc, cpsr -> cpsr
    mrs     r0, cpsr
    str     sp, [r1, #(MCONTEXT_ARM_SP - MCONTEXT_ARM_R4)]
    str     lr, [r1, #(MCONTEXT_ARM_PC - MCONTEXT_ARM_R4)]
    str     r0, [r1, #(MCONTEXT_ARM_CPSR - MCONTEXT_ARM_R4)]

    @ Store 0 -> r0 and return it
    mov     r0, #0
    str     r0, [r1, #(MCONTEXT_ARM_R0 - MCONTEXT_ARM_R4)]
    bx      lr
