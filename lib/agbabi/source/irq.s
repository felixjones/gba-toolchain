@--------------------------------------------------------------------------------
@ irq.s
@--------------------------------------------------------------------------------
@ Collection of default irq handlers
@ __agbabi_irq_empty | Does nothing but acknowledge raised IRQs
@--------------------------------------------------------------------------------

#define REG_BASE    0x4000000
#define REG_IE_IF   0x4000200
#define REG_IF      0x4000202
#define REG_BIOSIF  0x3FFFFF8

    .section .iwram,"ax",%progbits
    .align 2
    .arm
    .global __agbabi_irq_empty
    .type __agbabi_irq_empty STT_FUNC
__agbabi_irq_empty:
    mov     r0, #REG_BASE

    @ r1 = REG_IE & REG_IF, r0 = &REG_IE_IF
    ldr     r1, [r0, #(REG_IE_IF - REG_BASE)]!
    and     r1, r1, r1, lsr #16

    @ r2 = REG_BIOSIF | r1
    ldr     r2, [r0, #(REG_BIOSIF - REG_IE_IF)]
    orr     r2, r2, r1

    @ Acknowledge REG_IF
    strh    r1, [r0, #(REG_IF - REG_IE_IF)]

    @ Acknowledge REG_BIOSIF
    str     r2, [r0, #(REG_BIOSIF - REG_IE_IF)]

    bx lr
