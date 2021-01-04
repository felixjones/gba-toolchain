@--------------------------------------------------------------------------------
@ memset.s
@--------------------------------------------------------------------------------
@ Implementations of:
@   __aeabi_memset8, __aeabi_memset4 and __aeabi_memset
@   (void *dest, size_t n, int c)
@ memset8 is an alias of memset4
@ memset4 dest is word-aligned
@ memset might not be word-aligned
@ __agbabi_wordset4 sets words (does not reduce to lowest byte)
@   __aeabi_memclr8, __aeabi_memclr4 and __aeabi_memclr
@   (void *dest, size_t n)
@ memclr8 is an alias of memclr4
@ memclr4 dest is word-aligned, calls __agbabi_wordset4 with value 0
@ memclr might not be word-aligned, calls memset with value 0
@--------------------------------------------------------------------------------

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __aeabi_memset8
    .type __aeabi_memset8 STT_FUNC
__aeabi_memset8:
    .global __aeabi_memset4
    .type __aeabi_memset4 STT_FUNC
__aeabi_memset4:
    mov     r2, r2, lsl #24
    orr     r2, r2, r2, lsr #8
    orr     r2, r2, r2, lsr #16
    .global __agbabi_wordset4
    .type __agbabi_wordset4 STT_FUNC
__agbabi_wordset4:
    and     r3, r1, #3
    movs    r1, r1, lsr #2
    beq     .Lset

    and     r12, r1, #7
    movs    r1, r1, lsr #3
    beq     .Lset4

    @ r3 = bytes remaining, r12 = words remaining, r1 = 8 words remaining
    push    {r4-r10}
    mov     r4, r2
    mov     r5, r2
    mov     r6, r2
    mov     r7, r2
    mov     r8, r2
    mov     r9, r2
    mov     r10, r2
.Lset32:
    stmia   r0!, {r2, r4-r10}
    subs    r1, #1
    bne     .Lset32
    pop     {r4-r10}
.Lset4:
    subs    r12, #1
    strhs   r2, [r0], #4
    bhs     .Lset4
.Lset:
    subs    r3, r3, #1
    strhsb  r2, [r0], #1
    mov     r2, r2, lsr #8
    bhs     .Lset
    bx      lr

    .global __aeabi_memset
    .type __aeabi_memset STT_FUNC
__aeabi_memset:
    and     r3, r0, #3
    sub     r1, r1, r3
.Lcopy_front:
    subs    r3, r3, #1
    strhsb  r2, [r0], #1
    bhs     .Lcopy_front
    b       __aeabi_memset4

    .section .ewram, "ax", %progbits
    .align 2
    .thumb
    .global __aeabi_memclr8
    .type __aeabi_memclr8 STT_FUNC
__aeabi_memclr8:
    .global __aeabi_memclr4
    .type __aeabi_memclr4 STT_FUNC
__aeabi_memclr4:
    movs    r2, #0
    ldr     r3, =__agbabi_wordset4
    bx      r3

    .global __aeabi_memclr
    .type __aeabi_memclr STT_FUNC
__aeabi_memclr:
    movs    r2, #0
    ldr     r3, =__aeabi_memset
    bx      r3
