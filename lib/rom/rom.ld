/*
===============================================================================

 Copyright (C) 2021-2023 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(__start)

MEMORY {
    ewram : ORIGIN = 0x2000000, LENGTH = 256K
    iwram : ORIGIN = 0x3000000, LENGTH = 32K
    rom   : ORIGIN = 0x8000000, LENGTH = 32M
}

__sp_irq = ORIGIN(iwram) + LENGTH(iwram) - 0x60;
__sp_usr = __sp_irq - 0xA0;
__sp_usr_reserve = 0x200;

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

    .init_array : {
        PROVIDE_HIDDEN(__preinit_array_start = .);
        KEEP(*(.preinit_array .preinit_array.*))
        PROVIDE_HIDDEN(__preinit_array_end = .);

        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(.init_array .init_array.*))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > rom

    .fini_array : {
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(.fini_array .fini_array.*))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > rom

    .ARM.exidx : {
        PROVIDE_HIDDEN(__exidx_start = .);
        *(.ARM.exidx.* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN(__exidx_end = .);
    } > rom

    PROVIDE_HIDDEN(__ewram_overlay_start = ORIGIN(ewram));
    PROVIDE_HIDDEN(__ewram_overlay_lma = ALIGN(4));
    . = __ewram_overlay_lma;

    OVERLAY : NOCROSSREFS AT(__ewram_overlay_lma) {
        .ewram0 { *(.ewram0 .ewram0.*) *.ewram0.*(.text .text.* .rodata .rodata.*) }
        .ewram1 { *(.ewram1 .ewram1.*) *.ewram1.*(.text .text.* .rodata .rodata.*) }
        .ewram2 { *(.ewram2 .ewram2.*) *.ewram2.*(.text .text.* .rodata .rodata.*) }
        .ewram3 { *(.ewram3 .ewram3.*) *.ewram3.*(.text .text.* .rodata .rodata.*) }
        .ewram4 { *(.ewram4 .ewram4.*) *.ewram4.*(.text .text.* .rodata .rodata.*) }
        .ewram5 { *(.ewram5 .ewram5.*) *.ewram5.*(.text .text.* .rodata .rodata.*) }
        .ewram6 { *(.ewram6 .ewram6.*) *.ewram6.*(.text .text.* .rodata .rodata.*) }
        .ewram7 { *(.ewram7 .ewram7.*) *.ewram7.*(.text .text.* .rodata .rodata.*) }
        .ewram8 { *(.ewram8 .ewram8.*) *.ewram8.*(.text .text.* .rodata .rodata.*) }
        .ewram9 { *(.ewram9 .ewram9.*) *.ewram9.*(.text .text.* .rodata .rodata.*) }
    } > ewram

    PROVIDE_HIDDEN(__ewram_start = ALIGN(4));
    PROVIDE_HIDDEN(__ewram_lma = ALIGN(__ewram_overlay_lma + (. - __ewram_overlay_start), 4));

    .ewram : AT(__ewram_lma) ALIGN(32) {
        KEEP(*(SORT(.ewram.sorted.*)))
        *(.ewram .ewram.*)
        *.ewram.*(.data .data.* .text .text.* .rodata .rodata.*)
        . = ALIGN(32);
    } > ewram

    PROVIDE_HIDDEN(__ewram_lma_end = ALIGN(__ewram_lma + (. - __ewram_start), 4));

    .sbss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__sbss_start = ABSOLUTE(.));
        *(.sbss .sbss.*)
        . = ALIGN(32);
        PROVIDE_HIDDEN(__sbss_end = ABSOLUTE(.));
    } > ewram

    PROVIDE_HIDDEN(end = ALIGN(__sbss_end, 4));
    PROVIDE_HIDDEN(__end__ = end);

    PROVIDE_HIDDEN(__iwram_overlay_start = ORIGIN(iwram));
    PROVIDE_HIDDEN(__iwram_overlay_lma = __ewram_lma_end);
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

    PROVIDE_HIDDEN(__iwram_lma_end = ALIGN(__iwram_lma + SIZEOF(.iwram), 4));

    .bss(NOLOAD) : ALIGN(32) {
        PROVIDE_HIDDEN(__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(32);
        PROVIDE_HIDDEN(__bss_end = ABSOLUTE(.));
    } > iwram

    . = __iwram_lma_end;

    .text : AT(__iwram_lma_end) {
        EXCLUDE_FILE(*.iwram.* *.ewram.* *.iwram[0-9].* *.ewram[0-9].*) *(.text .text.* .gnu.linkonce.t.*)
        . = ALIGN(4);
    }

    .rodata : {
        EXCLUDE_FILE(*.iwram.* *.ewram.* *.iwram[0-9].* *.ewram[0-9].*) *(.rodata .rodata.* .gnu.linkonce.r.*)
    }

    PROVIDE_HIDDEN(__rom_end = ALIGN(256));
}
