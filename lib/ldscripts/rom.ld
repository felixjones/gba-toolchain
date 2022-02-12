/*
===============================================================================

Linker script for GBA ROMs

Copyright (C) 2021-2022 gba-toolchain contributors
For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
    ewram : ORIGIN = 0x2000000, LENGTH = 256K
    iwram : ORIGIN = 0x3000000, LENGTH = 32K
    rom   : ORIGIN = 0x8000000, LENGTH = 32M
}

__sp_irq = ORIGIN(iwram) + LENGTH(iwram) - 0x60;
__sp_usr = __sp_irq - 0xA0;
__sp_usr_reserve = 0x200; /* Estimated reserved user stack */

SECTIONS {
    /* Binary starts at rom */
    PROVIDE_HIDDEN (__rom_start = ORIGIN(rom));
    . = __rom_start;

    /* crt0.s should start with the ROM header, so that comes first */
    .crt0 : ALIGN(4) {
        KEEP (*(.crt0))
        KEEP (gba-runtime-*.*(.text .text.* .data .data.*))
        . = ALIGN(4);

        /* CpuSet constants */
        PROVIDE_HIDDEN (__ewram_cpuset = ABSOLUTE(.));
        LONG(__ewram_lma)
        LONG(__ewram_start)
        LONG((SIZEOF(.ewram) / 4) | (1 << 26))

        PROVIDE_HIDDEN (__iwram_cpuset = ABSOLUTE(.));
        LONG(__iwram_lma)
        LONG(__iwram_start)
        LONG((SIZEOF(.iwram) / 4) | (1 << 26))

        PROVIDE_HIDDEN (__bss_cpuset_fill = (SIZEOF(.bss) / 4) | (5 << 24));
        PROVIDE_HIDDEN (__sbss_cpuset_fill = (SIZEOF(.sbss) / 4) | (5 << 24));
    } > rom

    .text : ALIGN(4) {
        *(.text .text.* .gnu.linkonce.t.*)
    } > rom

    .preinit_array : ALIGN(4) {
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);
    } > rom

    .init_array : ALIGN(4) {
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
        PROVIDE_HIDDEN (__init_array_end = .);
    } > rom

    .fini_array : ALIGN(4) {
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
        PROVIDE_HIDDEN (__fini_array_end = .);
    } > rom

    /* ARM exception handling */
    .ARM.extab : ALIGN(4) {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > rom

    . = ALIGN(4);
    .ARM.exidx : ALIGN(4) {
        PROVIDE_HIDDEN (__exidx_start = .);
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN (__exidx_end = .);
    } > rom

    /* C++ exception handling */
    .eh_frame_hdr : ALIGN(4) {
        *(.eh_frame_hdr)
        *(.eh_frame_entry .eh_frame_entry.*)
    } > rom

    .eh_frame : ALIGN(4) {
        KEEP (*(.eh_frame))
        *(.eh_frame.*)
    } > rom

    /* Read only data */
    .rodata : ALIGN(4) {
        *(SORT(.rodata.sorted.*))
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    } > rom

    /* IWRAM */

    PROVIDE_HIDDEN (__iwram_start = ORIGIN(iwram));
    PROVIDE_HIDDEN (__iwram_lma = ALIGN(4));

    .iwram : AT(__iwram_lma) ALIGN(4) {
        KEEP (*(SORT(.iwram.sorted.*)))
        *(.iwram .iwram.*)
        *.iwram.*(.text .text.* .data .data.*)
        . = ALIGN(4);

        /* .data */
        PROVIDE_HIDDEN (__data_start = ABSOLUTE(.));
        *(.data .data.* .gnu.linkonce.d.*)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__data_end = ABSOLUTE(.));
    } > iwram

    /* IWRAM overalys */

    OVERLAY : NOCROSSREFS AT(__iwram_lma + SIZEOF(.iwram)) {
        .iwram0 { __iwram_overlay = ABSOLUTE(.); *(.iwram0 .iwram0.*) *.iwram0.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram1 { *(.iwram1 .iwram1.*) *.iwram1.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram2 { *(.iwram2 .iwram2.*) *.iwram2.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram3 { *(.iwram3 .iwram3.*) *.iwram3.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram4 { *(.iwram4 .iwram4.*) *.iwram4.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram5 { *(.iwram5 .iwram5.*) *.iwram5.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram6 { *(.iwram6 .iwram6.*) *.iwram6.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram7 { *(.iwram7 .iwram7.*) *.iwram7.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram8 { *(.iwram8 .iwram8.*) *.iwram8.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .iwram9 { *(.iwram9 .iwram9.*) *.iwram9.*(.text .text.* .data .data.*) . = ALIGN(32); }
    } > iwram

    /* Block starting symbol */

    .bss (NOLOAD) : ALIGN(4) {
        PROVIDE_HIDDEN (__bss_start = ABSOLUTE(.));
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__bss_end = ABSOLUTE(.));
    } > iwram

    PROVIDE_HIDDEN (__iwram_end = __bss_end);

    .stack : {
        ASSERT (__iwram_end <= (__sp_usr - __sp_usr_reserve), "IWRAM sections overlap with reserved stack");
    }

    /* EWRAM */

    PROVIDE_HIDDEN (__ewram_start = ORIGIN(ewram));
    PROVIDE_HIDDEN (__ewram_lma = ALIGN(__iwram_lma + (. - __iwram_start), 4));

    .ewram : AT(__ewram_lma) ALIGN(4) {
        KEEP (*(SORT(.ewram.sorted.*)))
        *(.ewram .ewram.*)
        *.ewram.*(.data .data.* .text .text.*)
        . = ALIGN(4);
    } > ewram

    /* ewram overalys */

    OVERLAY : NOCROSSREFS AT(__ewram_lma + SIZEOF(.ewram)) {
        .ewram0 { __ewram_overlay = ABSOLUTE(.); *(.ewram0 .ewram0.*) *.ewram0.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram1 { *(.ewram1 .ewram1.*) *.ewram1.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram2 { *(.ewram2 .ewram2.*) *.ewram2.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram3 { *(.ewram3 .ewram3.*) *.ewram3.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram4 { *(.ewram4 .ewram4.*) *.ewram4.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram5 { *(.ewram5 .ewram5.*) *.ewram5.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram6 { *(.ewram6 .ewram6.*) *.ewram6.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram7 { *(.ewram7 .ewram7.*) *.ewram7.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram8 { *(.ewram8 .ewram8.*) *.ewram8.*(.text .text.* .data .data.*) . = ALIGN(32); }
        .ewram9 { *(.ewram9 .ewram9.*) *.ewram9.*(.text .text.* .data .data.*) . = ALIGN(32); }
    } > ewram

    /* Small block starting symbol */

    .sbss (NOLOAD) : ALIGN(4) {
        PROVIDE_HIDDEN (__sbss_start = ABSOLUTE(.));
        *(.sbss .sbss.*)
        *(COMMON)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__sbss_end = ABSOLUTE(.));
    } > ewram

    PROVIDE_HIDDEN (__ewram_end = __sbss_end);

    PROVIDE_HIDDEN (__rom_end = ALIGN(ABSOLUTE(.), 4));
}
