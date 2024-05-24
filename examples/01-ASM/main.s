@===============================================================================
@
@ Copyright (C) 2021-2024 gba-toolchain contributors
@ For conditions of distribution and use, see copyright notice in LICENSE.md
@
@===============================================================================

    .thumb
    .text
    .global main
main:
    ldr     r1, =#0x04000000
    ldr     r0, =#0x0403
    strh    r0, [r1]

    ldr     r1, =#0x06000000

    mov     r0, #0x001F
    ldr     r2, =#((120 + 80 * 240) * 2)
    strh    r0, [r1, r2]

    ldr     r0, =#0x03E0
    ldr     r2, =#((136 + 80 * 240) * 2)
    strh    r0, [r1, r2]

    ldr     r0, =#0x7C00
    ldr     r2, =#((120 + 96 * 240) * 2)
    strh    r0, [r1, r2]

    swi     0x02
