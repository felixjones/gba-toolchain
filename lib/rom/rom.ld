OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(__start)

MEMORY {
    ewram : ORIGIN = 0x2000000, LENGTH = 256K
    iwram : ORIGIN = 0x3000000, LENGTH = 32K
    rom   : ORIGIN = 0x8000000, LENGTH = 32M
}

SECTIONS {
    . = ORIGIN(rom);

    .crt0 : {
        KEEP (*(.crt0))
    } > rom

    .text : {
        *(.text .text.* .gnu.linkonce.t.*)
    } > rom

    .ARM.exidx : {
        PROVIDE_HIDDEN (__exidx_start = .);
        *(.gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN (__exidx_end = .);
    } > rom
}
