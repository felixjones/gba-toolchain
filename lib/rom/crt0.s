@----------------------------------------
@ crt0.s
@----------------------------------------

  .section .crt0, "ax"
  .align 2
  .arm
  .global _start
_start:
  @ Immediately jump past header data to ROM code
  b	.Lrom_start

  @ Header data
  .fill 156, 1, 0   @ Nintendo logo (0x8000004)
  .fill	16, 1, 0    @ Game title
  .byte 0x00, 0x00	@ Developer ID	(0x80000B0)
  .byte 0x96		    @ Fixed value		(0x80000B2)
  .byte 0x00		    @ Main unit ID	(0x80000B3)
  .byte 0x00		    @ Device type		(0x80000B4)
  .fill	3, 1, 0x00	@ Unused byte x3
  
  .fill	4, 1, 0x00	@ Unused byte x4
  .byte	0x00		    @ Game version		  (0x80000BC)
  .byte	0x00		    @ Complement check  (0x80000BD)
  .byte	0x00, 0x00  @ Checksum          (0x80000BE)

.Lrom_start:
  @ r3 set to REG_BASE
  mov r3, #0x4000000

  @ Set IME to REG_BASE, disables interrupts (May have jumped here from game code)
  str r3, [r3, #0x208]

  @ Set IRQ stack pointer
  mov	r0, #0x12
  msr cpsr, r0	@ Switch to IRQ mode (0x12)
  ldr	sp, =__sp_irq

  @ Set user stack pointer
  mov	r0, #0x1F
  msr	cpsr, r0	@ Switch to user mode (0x1F)
  ldr	sp, =__sp_usr

  @ Enter thumb mode (bit 0 is set to 1)
  adr	r0, .Lthumb_start + 1
  bx	r0

  .thumb
.Lthumb_start:
  @ Slow copy IWRAM: __aeabi_memclr4 and __aeabi_memcpy4 might be in there
  ldr	r0, =__iwram_lma
  ldr	r1, =__iwram_start
  ldr	r2, =__iwram_end
.Liwram_copy:
  ldm   r0!, {r3-r7}
  stm   r1!, {r3-r7}
  cmp   r1, r2
  blt	.Liwram_copy

  @ Clear bss
  ldr	r0, =__bss_start
  ldr	r1, =__bss_end
  sub	r1, r0
  bl	__aeabi_memclr4

  @ Copy data
  ldr	r0, =__data_start
  ldr	r1, =__data_lma
  ldr	r2, =__data_end
  sub	r2, r0
  bl	__aeabi_memcpy4

  @ Copy EWRAM
  ldr	r0, =__ewram_start
  ldr	r1, =__ewram_lma
  ldr	r2, =__ewram_end
  sub	r2, r0
  bl	__aeabi_memcpy4

  @ __libc_init_array
  ldr	r2, =__libc_init_array
  bl	.Lbx_r2

  @ main
  mov	r0, #0		@ argc
  mov	r1, #0		@ argv
  ldr	r2, =main
  bl	.Lbx_r2

  @ Store result of main
  push  {r0}

  @ __libc_fini_array
  ldr r2, =__libc_fini_array
  bl	.Lbx_r2

  @ Restore result of main
  pop	{r0}
  ldr	r2, =_exit
  @ fallthrough

.Lbx_r2:
  bx  r2
