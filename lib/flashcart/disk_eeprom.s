@----------------------------------------
@ disk_eeprom.s
@----------------------------------------

    .section .disk0, "ax"
    .align 2
    .arm
    .global _eeprom_disk_status
_eeprom_disk_status:
    .global _eeprom_disk_initialize
_eeprom_disk_initialize:
    .global _eeprom_disk_ioctl
_eeprom_disk_ioctl:
    .global _eeprom_disk_fattime
_eeprom_disk_fattime:
    mov     r0, #0
    bx      lr

    .global _eeprom_disk_read
_eeprom_disk_read:
    push    {r4, r5}
    mov     r4, #0x04000000
    ldr     r12, [r4, #0x208]
    orr     r5, r12, #0x0300
    str     r5, [r4, #0x208]

    @ TODO : Read

    str     r12, [r4, #0x208]
    pop     {r4, r5}
    bx      lr

    .global _eeprom_disk_write
_eeprom_disk_write:
    push    {r4, r5}
    mov     r4, #0x04000000
    ldr     r12, [r4, #0x208]
    orr     r5, r12, #0x0300
    str     r5, [r4, #0x208]

    @ TODO : Write

    str     r12, [r4, #0x208]
    pop     {r4, r5}
    bx      lr
