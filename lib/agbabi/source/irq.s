@--------------------------------------------------------------------------------
@ irq.s
@--------------------------------------------------------------------------------
@ Collection of default irq handlers
@ __agbabi_irq_empty | Does nothing but acknowledge raised IRQs
@ __agbabi_irq_user  | Executes a provided function in user mode (__agbabi_irq_uproc)
@--------------------------------------------------------------------------------

#define REG_BIOSIF  0x3FFFFF8
#define REG_BASE    0x4000000
#define REG_IE_IF   0x4000200
#define REG_IF      0x4000202
#define REG_IME     0x4000208

    .section .iwram,"ax",%progbits
    .align 2
    .weak __agbabi_irq_uproc
__agbabi_irq_uproc:
    .word  0x00000000

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

    @ Acknowledge REG_IF and REG_BIOSIF
    strh    r1, [r0, #(REG_IF - REG_IE_IF)]
    str     r2, [r0, #(REG_BIOSIF - REG_IE_IF)]

    bx lr

    .section .iwram,"ax",%progbits
    .align 2
    .arm
    .global __agbabi_irq_user
    .type __agbabi_irq_user STT_FUNC
__agbabi_irq_user:
    mov     r1, #REG_BASE

    @ r1 = REG_IE & REG_IF, r0 = &REG_IE_IF
    ldr     r0, [r1, #(REG_IE_IF - REG_BASE)]!
    and     r0, r0, r0, lsr #16

    @ r2 = REG_BIOSIF | r0
    ldr     r2, [r1, #(REG_BIOSIF - REG_IE_IF)]
    orr     r2, r2, r0

    @ Acknowledge REG_IF and REG_BIOSIF
    strh    r0, [r1, #(REG_IF - REG_IE_IF)]
    str     r2, [r1, #(REG_BIOSIF - REG_IE_IF)]

    @ Clear handled from REG_IE
    ldrh    r2, [r1]
    bic     r2, r2, r0
    strh    r2, [r1]

    @ Disable REG_IME
    mov     r2, #0
    str     r2, [r1, #(REG_IME - REG_IE_IF)]

    @ Change to user mode
    mrs     r2, cpsr
    bic     r2, r2, #0xdf
    orr     r2, r2, #0x1f
    msr     cpsr, r2

    @ Load user IRQ proc
    .weak   __agbabi_irq_uproc
    ldr     r2, =__agbabi_irq_uproc
    ldr     r2, [r2]

    push    { r0-r1, r4-r11, lr }

    @ Call __agbabi_irq_proc
    mov     lr, pc
    bx      r2

    pop     { r0-r1, r4-r11, lr }

    @ Disable REG_IME again
    mov     r2, #0
    str     r2, [r1, #(REG_IME - REG_IE_IF)]

    @ Change to irq mode
    mrs     r2, cpsr
    bic     r2, r2, #0xdf
    orr     r2, r2, #0x92
    msr     cpsr, r2

    @ Restore REG_IE
    ldrh    r2, [r1]
    orr     r2, r2, r0
    strh    r2, [r1]

    @ Enable REG_IME
    mov     r2, #1
    str     r2, [r1, #(REG_IME - REG_IE_IF)]

    bx lr
