@--------------------------------------------------------------------------------
@ memcpy.s
@--------------------------------------------------------------------------------
@ Implementations of:
@   __aeabi_memcpy8, __aeabi_memcpy4 and __aeabi_memcpy
@   (void *dest, const void *src, size_t n)
@ memcpy8 is an alias of memcpy4
@ memcpy4 dest * src are word-aligned
@ memcpy might not be word-aligned
@--------------------------------------------------------------------------------

    .section .iwram, "ax", %progbits
    .align 2
    .arm
    .global __aeabi_memcpy8
    .type __aeabi_memcpy8 STT_FUNC
__aeabi_memcpy8:
    .global __aeabi_memcpy4
    .type __aeabi_memcpy4 STT_FUNC
__aeabi_memcpy4:
    and     r12, r2, #3
    movs    r2, r2, lsr #2
    beq     .Lcopy

    push    {r11}
    and     r11, r2, #7
    movs    r2, r2, lsr #3
    beq     .Lcopy4

    @ r12 = bytes remaining, r11 = words remaining, r2 = 8 words remaining
    push    {r4-r10}
.Lcopy32:
    ldmia   r1!, {r3-r10}
    stmia   r0!, {r3-r10}
    subs    r2, #1
    bne     .Lcopy32
    pop     {r4-r10}
.Lcopy4:
    subs    r11, #1
    ldrhs   r3, [r1], #4
    strhs   r3, [r0], #4
    bhs     .Lcopy4
    pop     {r11}
.Lcopy:
    subs    r12, r12, #1
    ldrhsb  r3, [r1], #1
    strhsb  r3, [r0], #1
    bhs     .Lcopy
    bx      lr

    .global __aeabi_memcpy
    .type __aeabi_memcpy STT_FUNC
__aeabi_memcpy:
    and     r3, r0, #3
    and     r12, r1, #3
    cmp     r3, r12
    bne     .Lunaligned

    rsb     r12, r12, #4
    sub     r2, r2, r12
.Lcopy_front:
    subs    r12, r12, #1
    ldrhsb  r3, [r1], #1
    strhsb  r3, [r0], #1
    bhs     .Lcopy_front
    b       __aeabi_memcpy4
.Lunaligned:
    subs    r2, r2, #1
    ldrhsb  r3, [r1], #1
    strhsb  r3, [r0], #1
    bhs     .Lunaligned
    bx      lr
