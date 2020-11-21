@--------------------------------------------------------------------------------
@ setcontext.s
@--------------------------------------------------------------------------------
@ Sort of based on https://www.man7.org/linux/man-pages/man3/setcontext.3.html
@--------------------------------------------------------------------------------

#define MCONTEXT_ARM_R0     12
#define MCONTEXT_ARM_SP     64
#define MCONTEXT_ARM_LR     68
#define MCONTEXT_ARM_PC     72
#define MCONTEXT_ARM_CPSR   76

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_setcontext
    .type   __agbabi_setcontext STT_FUNC
__agbabi_setcontext:
    @ Restore cpsr
    ldr     r12, [r0, #MCONTEXT_ARM_CPSR]
    msr     cpsr, r12

    @ Restore sp, lr
    ldr     sp, [r0, #MCONTEXT_ARM_SP]
    ldr     lr, [r0, #MCONTEXT_ARM_LR]

    @ Restore r0-r11
    add     r12, r0, #MCONTEXT_ARM_R0
    ldmia   r12, {r0-r11}

    @ Restore pc and bx to it
    ldr     r12, [r12, #(MCONTEXT_ARM_PC - MCONTEXT_ARM_R0)]
    bx      r12

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __agbabi_ctx_start
    .type   __agbabi_ctx_start STT_FUNC
__agbabi_ctx_start:
    movs    r0, r4
    bne     __agbabi_setcontext
    b       __rom_start
