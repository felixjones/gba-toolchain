@----------------------------------------
@ disk_ezflash.s
@----------------------------------------

    .section .disk4, "ax"
    .align 2
    .arm
    .global _ezflash_disk_status
_ezflash_disk_status:
    .global _ezflash_disk_initialize
_ezflash_disk_initialize:
    .global _ezflash_disk_read
_ezflash_disk_read:
    .global _ezflash_disk_write
_ezflash_disk_write:
    .global _ezflash_disk_ioctl
_ezflash_disk_ioctl:
    .global _ezflash_disk_fattime
_ezflash_disk_fattime:
    mov     r0, #0
    bx      lr
