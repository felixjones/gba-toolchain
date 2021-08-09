@----------------------------------------
@ disk_everdrive.s
@----------------------------------------

    .section .disk1, "ax"
    .align 2
    .arm
    .global _everdrive_disk_status
_everdrive_disk_status:
    .global _everdrive_disk_initialize
_everdrive_disk_initialize:
    .global _everdrive_disk_read
_everdrive_disk_read:
    .global _everdrive_disk_write
_everdrive_disk_write:
    .global _everdrive_disk_ioctl
_everdrive_disk_ioctl:
    .global _everdrive_disk_fattime
_everdrive_disk_fattime:
    mov     r0, #0
    bx      lr
