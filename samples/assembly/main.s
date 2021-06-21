    .section .text, "ax", %progbits
    .align 2
    .arm
    .global main
    .type main STT_FUNC
main:
    mov     r0, #0x04000000
    mov     r1, #0x0003
    orr     r1, r1, #0x0400
    str     r1, [r0]
    ldr     r0, .LVID_MEM_RED
    mov     r1, #0x001f
    strh    r1, [r0]
    mov     r1, #0x03e0
    strh    r1, [r0, #32]
    ldr     r0, .LVID_MEM_BLUE
    mov     r1, #0x7c00
    strh    r1, [r0]
.Lloop_forever:
    b       .Lloop_forever
.LVID_MEM_RED:
    .long   0x060096f0
.LVID_MEM_BLUE:
    .long   0x0600b4f0
