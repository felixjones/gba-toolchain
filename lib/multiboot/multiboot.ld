OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
    ewram : ORIGIN = 0x2000000, LENGTH = 256K
    iwram : ORIGIN = 0x3000000, LENGTH = 32K
}

__sp_irq = ORIGIN(iwram) + LENGTH(iwram) - 0x60;
__sp_usr = __sp_irq - 0xA0;
__sp_usr_reserve = 0x200;

SECTIONS {
    . = ORIGIN(ewram);

    .crt0 : {
        KEEP(*(.crt0.preheader))
        KEEP(*(.mb.header))
        KEEP(*(.crt0.postheader))

        PROVIDE_HIDDEN(__sbss_swi0c = ABSOLUTE(((__sbss_end - __sbss_start) / 4) | (1 << 24)));
        PROVIDE_HIDDEN(__bss_swi0c = ABSOLUTE(((__bss_end - __bss_start) / 4) | (1 << 24)));

        PROVIDE_HIDDEN(__iwram_swi0c = ABSOLUTE((__iwram_lma_end - __iwram_lma) / 4));
    } > ewram

    .init_array : {
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array .preinit_array.*))
        PROVIDE_HIDDEN(__preinit_array_end = .);

        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(.init_array .init_array.*))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > ewram

    .fini_array : {
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(.fini_array .fini_array.*))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > ewram

    .ARM.exidx : {
        PROVIDE_HIDDEN(__exidx_start = .);
        *(.ARM.exidx.* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN(__exidx_end = .);
    } > ewram

    .sbss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__sbss_start = ABSOLUTE(.));
        *(.sbss .sbss.*)
        . = ALIGN(32);
        PROVIDE_HIDDEN(__sbss_end = ABSOLUTE(.));
    } > ewram

    PROVIDE_HIDDEN(__iwram_overlay_start = ORIGIN(iwram));
    PROVIDE_HIDDEN(__iwram_overlay_lma = ALIGN(4));
    . = __iwram_overlay_lma;

    OVERLAY : NOCROSSREFS AT(__iwram_overlay_lma) {
        .iwram0 { *(.iwram0 .iwram0.*) *.iwram0.*(.text .text.* .rodata .rodata.*) }
        .iwram1 { *(.iwram1 .iwram1.*) *.iwram1.*(.text .text.* .rodata .rodata.*) }
        .iwram2 { *(.iwram2 .iwram2.*) *.iwram2.*(.text .text.* .rodata .rodata.*) }
        .iwram3 { *(.iwram3 .iwram3.*) *.iwram3.*(.text .text.* .rodata .rodata.*) }
        .iwram4 { *(.iwram4 .iwram4.*) *.iwram4.*(.text .text.* .rodata .rodata.*) }
        .iwram5 { *(.iwram5 .iwram5.*) *.iwram5.*(.text .text.* .rodata .rodata.*) }
        .iwram6 { *(.iwram6 .iwram6.*) *.iwram6.*(.text .text.* .rodata .rodata.*) }
        .iwram7 { *(.iwram7 .iwram7.*) *.iwram7.*(.text .text.* .rodata .rodata.*) }
        .iwram8 { *(.iwram8 .iwram8.*) *.iwram8.*(.text .text.* .rodata .rodata.*) }
        .iwram9 { *(.iwram9 .iwram9.*) *.iwram9.*(.text .text.* .rodata .rodata.*) }
    } > iwram

    PROVIDE_HIDDEN(__iwram_start = ALIGN(4));
    PROVIDE_HIDDEN(__iwram_lma = ALIGN(__iwram_overlay_lma + (. - __iwram_overlay_start), 32));

    .iwram : AT(__iwram_lma) {
        KEEP(*(SORT(.iwram.sorted.*)))
        *(.iwram .iwram.*)
        *.iwram.*(.data .data.* .text .text.* .rodata .rodata.*)
        *(.data .data.* .gnu.linkonce.d.*)
        . = ALIGN(32);
    } > iwram

    PROVIDE_HIDDEN(__iwram_lma_end = ALIGN(__iwram_lma + (. - __iwram_start), 4));

    .bss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(32);
        PROVIDE_HIDDEN(__bss_end = ABSOLUTE(.));
    } > iwram

    . = __iwram_lma_end;

    .text : AT(__iwram_lma_end) {
        EXCLUDE_FILE(*.iwram.* *.iwram[0-9].*) *(.text .text.* .gnu.linkonce.t.*)
    }

    .rodata : {
        EXCLUDE_FILE(*.iwram.* *.iwram[0-9].*) *(.rodata .rodata.* .gnu.linkonce.r.*)
    }

    PROVIDE_HIDDEN(end = ALIGN(__iwram_lma_end + SIZEOF(.text) + SIZEOF(.rodata), 32));
    PROVIDE_HIDDEN(__end__ = end);
}
