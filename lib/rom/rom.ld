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
        KEEP(*(.crt0.preheader))
        KEEP(*(.cart.header))
        KEEP(*(.cart.backup))
        KEEP(*(.crt0.postheader))

        PROVIDE_HIDDEN(__sbss_swi0c = ABSOLUTE((SIZEOF(.sbss) / 4) | (1 << 24)));
        PROVIDE_HIDDEN(__bss_swi0c = ABSOLUTE((SIZEOF(.bss) / 4) | (1 << 24)));

        PROVIDE_HIDDEN(__ewram_swi0c = ABSOLUTE(SIZEOF(.ewram) / 4));
        PROVIDE_HIDDEN(__iwram_swi0c = ABSOLUTE(SIZEOF(.iwram) / 4));
    } > rom

    .text : {
        *(.text .text.* .gnu.linkonce.t.*)
    } > rom

    .ARM.exidx : {
        PROVIDE_HIDDEN(__exidx_start = .);
        *(.gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN(__exidx_end = .);
    } > rom

    PROVIDE_HIDDEN(__ewram_start = ORIGIN(ewram));
    PROVIDE_HIDDEN(__ewram_lma = ALIGN(4));

    .ewram : AT(__ewram_lma) ALIGN(32) {
        *(.ewram .ewram.*)
        *.ewram.*(.data .data.* .text .text.*)
        . = ALIGN(32);
    } > ewram

    .sbss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__sbss_start = ABSOLUTE(.));
        *(.sbss .sbss.*)
        . = ALIGN(32);
        PROVIDE_HIDDEN(__sbss_end = ABSOLUTE(.));
    } > ewram

    PROVIDE_HIDDEN(__ewram_lma_end = ALIGN(__ewram_lma + (. - __ewram_start), 4));
    . = __ewram_lma_end;

    PROVIDE_HIDDEN(__iwram_start = ORIGIN(iwram));
    PROVIDE_HIDDEN(__iwram_lma = ALIGN(4));

    .iwram : AT(__iwram_lma) ALIGN(32) {
        *(.iwram .iwram.*)
        *.iwram.*(.text .text.* .data .data.*)
        . = ALIGN(32);
    } > iwram

    .bss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(32);
    } > iwram

    PROVIDE_HIDDEN(__iwram_lma_end = ALIGN(__iwram_lma + (. - __iwram_start), 4));
}
