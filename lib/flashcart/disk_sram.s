@----------------------------------------
@ disk_sram.s
@----------------------------------------

    .section .disk1, "ax"
    .align 2
    .arm
    .global _sram_disk_status
_sram_disk_status:
    .global _sram_disk_initialize
_sram_disk_initialize:
    .global _sram_disk_read
_sram_disk_read:
    .global _sram_disk_write
_sram_disk_write:
    .global _sram_disk_ioctl
_sram_disk_ioctl:
    .global _sram_disk_fattime
_sram_disk_fattime:
    mov     r0, #0
    bx      lr
