@--------------------------------------------------------------------------------
@ setcontext.s
@--------------------------------------------------------------------------------
@ Implementation of https://www.man7.org/linux/man-pages/man3/setcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_R4     4
#define MCONTEXT_ARM_PC     48
#define MCONTEXT_ARM_CPSR   52

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_setcontext
    .type   __agbabi_setcontext STT_FUNC
__agbabi_setcontext:
    @ Restore r4-r12, sp and lr
    add     r1, r0, #MCONTEXT_ARM_R4
    ldmia   r1, {r4-r12, sp, lr}

    @ Load cpsr
    ldr     r1, [r0, #MCONTEXT_ARM_CPSR]
    msr     cpsr, r1

    @ Return 0
    ldr     r1, [r0, #MCONTEXT_ARM_PC]
    mov     r0, #0
    bx      r1
