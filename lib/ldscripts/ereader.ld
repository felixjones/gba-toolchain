/*
===============================================================================

Linker script for GBA e-reader binaries

Copyright (C) 2021-2022 gba-toolchain contributors
For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

/*
 * Memory regions
 */
MEMORY {
    ewram : ORIGIN = 0x02000000, LENGTH = 256K
    iwram : ORIGIN = 0x03000000, LENGTH = 32K
}

/*
 * Common symbols
 */
__iwram_base = ORIGIN(iwram);
__iwram_top  = ORIGIN(iwram) + LENGTH(iwram);
__ewram_base = ORIGIN(ewram);
__ewram_top  = ORIGIN(ewram) + LENGTH(ewram);
__sp_irq     = __iwram_top - 0x60;
__sp_usr     = __sp_irq - 0xA0;

/*
 * Sections
 */
SECTIONS {
    /*
     * EWRAM
     */

    . = __ewram_start;

    /* Compiler runtime entry point */
    .crt0 : ALIGN(4) {
        KEEP (*(.crt0))
        . = ALIGN(4);

        __ewram_data_cpuset = ABSOLUTE(.);
        LONG(__ewram_data_lma)
        LONG(__ewram_data_start)
        LONG(__ewram_data_cpuset_copy)
        . = ALIGN(4);

        __iwram_cpuset = ABSOLUTE(.);
        LONG(__iwram_lma)
        LONG(__iwram_start)
        LONG(__iwram_cpuset_copy)
        . = ALIGN(4);

        __data_cpuset = ABSOLUTE(.);
        LONG(__data_lma)
        LONG(__data_start)
        LONG(__data_cpuset_copy)
        . = ALIGN(4);
    } > ewram

    /* Program code */
    .text : ALIGN(4) {
        *(EXCLUDE_FILE (*.iwram.* *.iwram[0-9].*) .text*)
        *(.stub)
        . = ALIGN(4);
    } > ewram

    /*
     * Initialization
     */
    /* Pre-initialization array is called before _init */
    .preinit_array : ALIGN(4) {
        __preinit_array_start = ABSOLUTE(.);
        KEEP (*(.preinit_array))
        __preinit_array_end = ABSOLUTE(.);
        . = ALIGN(4);
    } > ewram

    .init : ALIGN(4) {
        KEEP (*(.init))
        . = ALIGN(4);
    } > ewram

    /* Initialization array is called after _init */
    .init_array : ALIGN(4) {
        __init_array_start = ABSOLUTE(.);
        KEEP (*(SORT(.init_array.*)))
        KEEP (*(.init_array))
        __init_array_end = ABSOLUTE(.);
        . = ALIGN(4);
    } > ewram

    /* Finalization code */
    .fini : ALIGN(4) {
        KEEP (*(.fini))
        . = ALIGN(4);
    } > ewram

    /* Initialization array is called after _fini */
    .fini_array : ALIGN(4) {
        __fini_array_start = ABSOLUTE(.);
        KEEP (*(SORT(.fini_array.*)))
        KEEP (*(.fini_array*))
        __fini_array_end = ABSOLUTE(.);
        . = ALIGN(4);
    } > ewram

    /*
     * Exception handling
     */
    .eh_frame : ALIGN(4) {
        KEEP (*(.eh_frame))
        *(.eh_frame.*)
        . = ALIGN(4);
    } > ewram

    /* Index entries for section unwinding */
    .ARM.extab : ALIGN(4) {
        *(.ARM.extab*)
    } > ewram

    . = ALIGN(4);
    PROVIDE(__exidx_start = .);
    .ARM.exidx : ALIGN(4) {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*);
    } > ewram
    . = ALIGN(4);
    PROVIDE(__exidx_end = .);

    /*
     * Read only data
     */
    .rodata : ALIGN(4) {
        *(.rodata .rodata.*)
        . = ALIGN(4);
    } > ewram

    /*
     * EWRAM data
     */

    __ewram_data_lma = ALIGN(4);

    .ewram : AT(__ewram_data_lma) ALIGN(4) {
        __ewram_data_start = ABSOLUTE(.);
        *ewram.*(.data*)
        . = ALIGN(4);
        __ewram_data_end = ABSOLUTE(.);
    } > ewram

    /*
     * IWRAM
     */
    /* IWRAM base load memory address (source) */
    __iwram_base_lma = ALIGN(4);

    .iwram.base __iwram_base : AT(__iwram_base_lma) ALIGN(4) {
        __iwram_base_start = ABSOLUTE(.);
        *(.iwram.base .iwram.base.*)
        *iwram.base.*(.text* .data*)
        . = ALIGN(4);
        __iwram_base_end = ABSOLUTE(.);
    } > iwram

    /* IWRAM load memory address (source) */
    __iwram_lma = __iwram_base_lma + ALIGN(SIZEOF(.iwram.base), 4);

    .iwram : AT(__iwram_lma) ALIGN(4) {
        __iwram_start = ABSOLUTE(.);
        *(.iwram .iwram.*)
        *iwram.*(.text* .data*)
        . = ALIGN(4);
        __iwram_end = ABSOLUTE(.);
    } > iwram

    /* Block starting symbol */
    .bss : ALIGN(4) {
        __bss_start = ABSOLUTE(.);
        *(.dynbss)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = ABSOLUTE(.);
    } > iwram

    /* data load memory address (source) */
    __data_lma = __iwram_lma + ALIGN(SIZEOF(.iwram), 4);

    .data : AT(__data_lma) ALIGN(4) {
        __data_start = ABSOLUTE(.);
        *(.data .data.*)
        SORT(CONSTRUCTORS)
        . = ALIGN(4);
        __data_end = ABSOLUTE(.);
    } > iwram

    /*
     * IWRAM overlays
     */

    __iwram_overlay_lma = __data_lma + ALIGN(SIZEOF(.data), 4);

    OVERLAY : NOCROSSREFS AT(__iwram_overlay_lma) {
        .iwram0 { __iwram_overlay = ABSOLUTE(.); *(.iwram0 .iwram0*) *iwram0.*(.text* .data*) . = ALIGN(4); __iwram0_end = ABSOLUTE(.); }
        .iwram1 { *(.iwram1 .iwram1*) *iwram1.*(.text* .data*) . = ALIGN(4); __iwram1_end = ABSOLUTE(.); }
        .iwram2 { *(.iwram2 .iwram2*) *iwram2.*(.text* .data*) . = ALIGN(4); __iwram2_end = ABSOLUTE(.); }
        .iwram3 { *(.iwram3 .iwram3*) *iwram3.*(.text* .data*) . = ALIGN(4); __iwram3_end = ABSOLUTE(.); }
        .iwram4 { *(.iwram4 .iwram4*) *iwram4.*(.text* .data*) . = ALIGN(4); __iwram4_end = ABSOLUTE(.); }
        .iwram5 { *(.iwram5 .iwram5*) *iwram5.*(.text* .data*) . = ALIGN(4); __iwram5_end = ABSOLUTE(.); }
        .iwram6 { *(.iwram6 .iwram6*) *iwram6.*(.text* .data*) . = ALIGN(4); __iwram6_end = ABSOLUTE(.); }
        .iwram7 { *(.iwram7 .iwram7*) *iwram7.*(.text* .data*) . = ALIGN(4); __iwram7_end = ABSOLUTE(.); }
        .iwram8 { *(.iwram8 .iwram8*) *iwram8.*(.text* .data*) . = ALIGN(4); __iwram8_end = ABSOLUTE(.); }
        .iwram9 { *(.iwram9 .iwram9*) *iwram9.*(.text* .data*) . = ALIGN(4); __iwram9_end = ABSOLUTE(.); }
    } > iwram

    __iwram0_size = __load_stop_iwram0 - __load_start_iwram0;
    __iwram1_size = __load_stop_iwram1 - __load_start_iwram1;
    __iwram2_size = __load_stop_iwram2 - __load_start_iwram2;
    __iwram3_size = __load_stop_iwram3 - __load_start_iwram3;
    __iwram4_size = __load_stop_iwram4 - __load_start_iwram4;
    __iwram5_size = __load_stop_iwram5 - __load_start_iwram5;
    __iwram6_size = __load_stop_iwram6 - __load_start_iwram6;
    __iwram7_size = __load_stop_iwram7 - __load_start_iwram7;
    __iwram8_size = __load_stop_iwram8 - __load_start_iwram8;
    __iwram9_size = __load_stop_iwram9 - __load_start_iwram9;

    __iwram0_cpuset_copy = ((__iwram0_size) / 4) | (1 << 26);
    __iwram1_cpuset_copy = ((__iwram1_size) / 4) | (1 << 26);
    __iwram2_cpuset_copy = ((__iwram2_size) / 4) | (1 << 26);
    __iwram3_cpuset_copy = ((__iwram3_size) / 4) | (1 << 26);
    __iwram4_cpuset_copy = ((__iwram4_size) / 4) | (1 << 26);
    __iwram5_cpuset_copy = ((__iwram5_size) / 4) | (1 << 26);
    __iwram6_cpuset_copy = ((__iwram6_size) / 4) | (1 << 26);
    __iwram7_cpuset_copy = ((__iwram7_size) / 4) | (1 << 26);
    __iwram8_cpuset_copy = ((__iwram8_size) / 4) | (1 << 26);
    __iwram9_cpuset_copy = ((__iwram9_size) / 4) | (1 << 26);

    __iwram_overlay_size =  __iwram0_size + __iwram1_size + __iwram2_size + __iwram3_size + __iwram4_size +
                            __iwram5_size + __iwram6_size + __iwram7_size + __iwram8_size + __iwram9_size;

    __iwram_overlay_end = __iwram_overlay + __iwram_overlay_size;

    /*
     * End of EWRAM symbol
     */

    __ewram_end = __iwram_overlay_lma + __iwram_overlay_size;

    /*
     * crt0.s CpuSet constants
     */

    __iwram_base_cpuset_copy = ((__iwram_base_end - __iwram_base_start) / 4) | (1 << 26);
    __iwram_cpuset_copy = ((__iwram_end - __iwram_start) / 4) | (1 << 26);
    __data_cpuset_copy = ((__data_end - __data_start) / 4) | (1 << 26);
    __ewram_data_cpuset_copy = ((__ewram_data_end - __ewram_data_start) / 4) | (1 << 26);
}
