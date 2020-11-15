@----------------------------------------
@ gba-irq.s
@----------------------------------------

  .section .iwram,"ax",%progbits
  .align 2
  .arm

  .global _gba_intr_empty
_gba_intr_empty:
  mov r3, #0x4000000
  mov r2, #0xFF
  strh r2, [r3, #-8]
  add r3, r3, #0x200
  strh r2, [r3, #2]
  mov pc, lr


  .global _gba_intr_wrapped
_gba_intr_wrapped:
  mov r3, #0x4000000 @ REG_BASE
  ldr r2, [r3, #0x200] @ Read REG_IE
  @ Get raised flags
  and r0, r2, r2, lsr #16 @ r0 = IE & IF

  @ combine with BIOS IRQ flags (0x3FFFFF8 mirror)
  ldrh r2, [r3, #-8]
  orr r2, r2, r0
  strh r2, [r3, #-8]

  add r3, r3, #0x200
  strh r0, [r3, #2] @ IF Clear

  @ Switch to system mode (IRQ stays disabled)
  msr cpsr_c, #0x9F

  mov r1, #0x3000000
  ldr r1, [r1]
  stmfd sp!, {lr}
  mov lr, pc
  bx r1
  ldmfd sp!, {lr}

  @ Switch to IRQ mode (IRQ stays disabled)
  msr cpsr_c, #0x92
  mov pc, lr


  .global _gba_intr_jump_table
_gba_intr_jump_table:
  mov r3, #0x4000000 @ REG_BASE
  ldr r2, [r3, #0x200] @ Read REG_IE

  @ Get raised flags
  and r0, r2, r2, lsr #16 @ r0 = IE & IF

@ combine with BIOS IRQ flags (0x3FFFFF8 mirror)
  ldrh r2, [r3, #-8]
  orr r2, r2, r0
  strh r2, [r3, #-8]

  add r3, r3, #0x200
  strh r0, [r3, #2] @ IF Clear

  @ Switch to system mode (IRQ stays disabled)
  msr cpsr_c, #0x9F

  mov r1, #0x3000000
  ldr r2, [r1]

.start:
  ldr r1, [r2]
  cmp r1, #0
  beq .end

  tst r1, r0
  beq .continue

  ldr r1, [r2, #4]

  push {r0-r3, lr}
  mov lr, pc
  bx r1
  pop {r0-r3, lr}

.continue:
  add r2, r2, #8
  b .start

.end:
  msr cpsr_c, #0x92
  mov pc, lr
