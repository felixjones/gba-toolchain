/*
===============================================================================

An example minimal linker script for C++ exceptions

Copyright (C) 2021-2022 gba-toolchain contributors
For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
    ewram : ORIGIN = 0x02000000, LENGTH = 256K
    iwram : ORIGIN = 0x03000000, LENGTH = 32K
    rom   : ORIGIN = 0x08000000, LENGTH = 32M
}

__iwram_base = ORIGIN(iwram);
__iwram_top  = ORIGIN(iwram) + LENGTH(iwram);
__ewram_base = ORIGIN(ewram);
__ewram_top  = ORIGIN(ewram) + LENGTH(ewram);
__sp_irq     = __iwram_top - 0x60;
__sp_usr     = __sp_irq - 0xA0;

SECTIONS {
    . = ORIGIN(rom);

    .crt0 : ALIGN(4) {
        KEEP (*(.crt0))
    } > rom

    .text : ALIGN(4) {
        *(.text.unlikely .text.*_unlikely .text.unlikely.*)
        *(.text.exit .text.exit.*)
        *(.text.startup .text.startup.*)
        *(.text.hot .text.hot.*)
        *(SORT(.text.sorted.*))
        *(.text .stub .text.* .gnu.linkonce.t.*)
        *(.glue_7t) *(.glue_7)
    } > rom

    .rodata : ALIGN(4) {
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    } > rom

    .ARM.extab : ALIGN(4) {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > rom

    . = ALIGN(4);
    .ARM.exidx : ALIGN(4) {
        PROVIDE_HIDDEN (__exidx_start = .);
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN (__exidx_end = .);
    } > rom

    .eh_frame_hdr : ALIGN(4) {
        *(.eh_frame_hdr) *(.eh_frame_entry .eh_frame_entry.*)
    } > rom

    .eh_frame : ALIGN(4) {
        KEEP (*(.eh_frame)) *(.eh_frame.*)
    } > rom

    __data_lma = ALIGN(4);

    .data __iwram_base : AT(__data_lma) ALIGN(4) {
        __data_start = ABSOLUTE(.);
        *(.data .data.*)
        SORT(CONSTRUCTORS)
        . = ALIGN(4);
        __data_end = ABSOLUTE(.);
    } > iwram

    .bss : ALIGN(4) {
        __bss_start = ABSOLUTE(.);
        *(.dynbss)
        *(.bss .bss.* .gnu.linkonce.b.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = ABSOLUTE(.);
    } > iwram

    __bss_cpuset_fill = ((__bss_end - __bss_start) / 4) | (5 << 24);
    __data_cpuset_copy = ((__data_end - __data_start) / 4) | (1 << 26);
}
