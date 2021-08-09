@----------------------------------------
@ disk_flash.s
@----------------------------------------

#define FLASH_SECTOR_SIZE_LOG2  ( 9 )
#define FLASH_SECTOR_SIZE       ( 1 << FLASH_SECTOR_SIZE_LOG2 )
#define FLASH_SECTOR_COUNT      ( 131072 / SRAM_SECTOR_SIZE )
#define FLASH_BLOCK_SIZE        ( 1 )
#define FLASH_BASE_ADDRESS      ( 0x0e000000 )

#define BANK_SIZE_LOG2  ( 16 )
#define BANK_SIZE       ( 1 << BANK_SIZE_LOG2 )

    .section .disk0, "ax"
    .align 2
    .arm
    .global _flash_disk_status
_flash_disk_status:
    .global _flash_disk_initialize
_flash_disk_initialize:
    .global _flash_disk_ioctl
_flash_disk_ioctl:
    .global _flash_disk_fattime
_flash_disk_fattime:
    mov     r0, #0
    bx      lr

    .global _flash_disk_read
_flash_disk_read:
    @ Select bank

    .global _flash_disk_write
_flash_disk_write:
    push    {lr}
    @ Adjust address from sectors to byte
    lsl     r2, r2, #FLASH_SECTOR_SIZE_LOG2
    lsr     r0, r2, #16     @ r0 = start bank


    bl      .Lflash_select_bank

    @ Enter write mode
    mov     r0, #0xa0
    bl      .Lflash_select_mode

    @ Write bytes

    @ Return to normal mode
    mov     r0, #0xf0
    bl      .Lflash_select_mode
    pop     {lr}
    bx      lr

.Lflash_select_bank:
    mov     r1, r0
    push    {lr}

    @ Enter bank mode
    mov     r0, #0xb0
    bl      .Lflash_select_mode

    @ Set bank
    mov     r0, #FLASH_BASE_ADDRESS
    strb    r1, [r0]

    @ Return to normal mode
    mov     r0, #0xf0
    bl      .Lflash_select_mode

    pop     {lr}
    bx      lr

.Lflash_select_mode:
    push    {r0, lr}
    bl      .Lflash_waitcnt8
    pop     {r12, lr}

    ldr     r3, .Lflash_command_address_hi
    ldr     r2, .Lflash_command_address_lo
    mov     r1, #0xaa
    strb    r1, [r3]
    mov     r1, #0x55
    strb    r1, [r2]
    @ Set Mode
    strb    r12, [r3]

    push    {lr}
    bl      .Lflash_waitcnt_restore
    pop     {lr}
    bx      lr

.Lflash_waitcnt8:
    mov     r2, #0x04000000
    ldr     r0, [r2, #0x204]
    orr     r1, r0, #0x0300
    str     r1, [r2, #0x204]
    bx      lr

.Lflash_waitcnt_restore:
    mov     r1, #0x04000000
    str     r0, [r1, #0x204]
    bx      lr

.Lflash_command_address_hi:
    .long   FLASH_BASE_ADDRESS + 0x5555
.Lflash_command_address_lo:
    .long   FLASH_BASE_ADDRESS + 0x2aaa
