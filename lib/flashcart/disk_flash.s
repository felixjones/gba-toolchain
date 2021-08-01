@----------------------------------------
@ disk_flash.s
@----------------------------------------

    .section .disk2, "ax"
    .align 2
    .arm
    .global _flash_disk_status
_flash_disk_status:
    .global _flash_disk_initialize
_flash_disk_initialize:
    .global _flash_disk_read
_flash_disk_read:
    .global _flash_disk_write
_flash_disk_write:
    .global _flash_disk_ioctl
_flash_disk_ioctl:
    .global _flash_disk_fattime
_flash_disk_fattime:
    mov     r0, #0
    bx      lr
