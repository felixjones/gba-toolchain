/*
===============================================================================

Linker script for GBA e-reader binaries

Copyright (C) 2021-2022 gba-toolchain contributors
For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(__start)

MEMORY {
    ewram : ORIGIN = 0x2000000, LENGTH = 256K
    iwram : ORIGIN = 0x3000000, LENGTH = 32K
}

__sp_irq = ORIGIN(iwram) + LENGTH(iwram) - 0x60;
__sp_usr = __sp_irq - 0xA0;
__sp_usr_reserve = 0x200; /* Estimated reserved user stack */
__ewram_lma = 0x8000000; /* If starting as ROM, copy into EWRAM */

SECTIONS {
    /* Binary starts at ewram */
    PROVIDE_HIDDEN (__ewram_start = ORIGIN(ewram));
    . = __ewram_start;

    /* crt0.s should start with the Multiboot header, so that comes first */
    .crt0 : ALIGN(4) {
        KEEP (*(.crt0))
        . = ALIGN(4);

        /* CpuSet constants */
        PROVIDE_HIDDEN (__ewram_data_cpuset = ABSOLUTE(.));
        LONG (__ewram_data_lma)
        LONG (__ewram_data_start)
        LONG ((SIZEOF(.ewram) / 4) | (1 << 26))

        PROVIDE_HIDDEN (__iwram_cpuset = ABSOLUTE(.));
        LONG (__iwram_lma)
        LONG (__iwram_start)
        LONG ((SIZEOF(.iwram) / 4) | (1 << 26))

        PROVIDE_HIDDEN (__sbss_cpuset_fill = ABSOLUTE((SIZEOF(.sbss) / 4) | (5 << 24)));
    } > ewram

    .text : ALIGN(4) {
        EXCLUDE_FILE (*.iwram.* *.iwram[0-9].*) *(.text .text.* .gnu.linkonce.t.*)
    } > ewram

    .preinit_array : ALIGN(4) {
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP (*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);
    } > ewram

    .init_array : ALIGN(4) {
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP (*(.init_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .ctors))
        PROVIDE_HIDDEN (__init_array_end = .);
    } > ewram

    .fini_array : ALIGN(4) {
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP (*(SORT_BY_INIT_PRIORITY(.fini_array.*) SORT_BY_INIT_PRIORITY(.dtors.*)))
        KEEP (*(.fini_array EXCLUDE_FILE (*crtbegin.o *crtbegin?.o *crtend.o *crtend?.o ) .dtors))
        PROVIDE_HIDDEN (__fini_array_end = .);
    } > ewram

    /* ARM exception handling */
    .ARM.extab : ALIGN(4) {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > ewram

    . = ALIGN(4);
    .ARM.exidx : ALIGN(4) {
        PROVIDE_HIDDEN (__exidx_start = .);
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        PROVIDE_HIDDEN (__exidx_end = .);
    } > ewram

    /* C++ exception handling */
    .eh_frame_hdr : ALIGN(4) {
        *(.eh_frame_hdr)
        *(.eh_frame_entry .eh_frame_entry.*)
    } > ewram

    .eh_frame : ALIGN(4) {
        KEEP (*(.eh_frame))
        *(.eh_frame.*)
    } > ewram

    /* Read only data */
    .rodata : ALIGN(4) {
        *(SORT(.rodata.sorted.*))
        *(.rodata .rodata.* .gnu.linkonce.r.*)
    } > ewram

    /* EWRAM data */

    PROVIDE_HIDDEN (__ewram_data_lma = ALIGN(4));

    .ewram : AT(__ewram_data_lma) ALIGN(4) {
        PROVIDE_HIDDEN (__ewram_data_start = ABSOLUTE(.));
        *(.ewram .ewram.*)
        *.ewram.*(.data .data.*)

        /* data sections not included in iwram */
        *__atexit.*(.data .data.*)
        *__call_atexit.*(.data .data.*)
        *impure.*(.data .data.*)
        *lock.*(.data .data.*)
        *on_exit_args.*(.data .data.*)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__ewram_data_end = ABSOLUTE(.));
    } > ewram

    PROVIDE_HIDDEN (__ewram_data_lma_end = ALIGN(__ewram_data_lma + (. - __ewram_data_start), 4));

    /* Small block starting symbol */

    .sbss (NOLOAD) : ALIGN(4) {
        PROVIDE_HIDDEN (__sbss_start = ABSOLUTE(.));
        *(.sbss .sbss.*)

        /* bss sections not included in iwram */
        *__atexit.*(.bss .bss.*)
        *__call_atexit.*(.bss .bss.*)
        *impure.*(.bss .bss.*)
        *lock.*(.bss .bss.*)
        *on_exit_args.*(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__sbss_end = ABSOLUTE(.));
    } > ewram

    /* IWRAM */

    PROVIDE_HIDDEN (__iwram_start = ORIGIN(iwram));
    PROVIDE_HIDDEN (__iwram_lma = ALIGN(__ewram_data_lma_end, 4));

    .iwram : AT(__iwram_lma) ALIGN(4) {
        KEEP (*(SORT(.iwram.sorted.*)))
        *(.iwram .iwram.*)
        *.iwram.*(.text .text.* .data .data.*)
        . = ALIGN(4);

        /* .data */
        PROVIDE_HIDDEN (__data_start = ABSOLUTE(.));
        EXCLUDE_FILE (*__atexit.* *__call_atexit.* *impure.* *lock.* *on_exit_args.*) *(.data .data.* .gnu.linkonce.d.*)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__data_end = ABSOLUTE(.));
    } > iwram

    /* IWRAM overalys */

    OVERLAY : NOCROSSREFS AT(__iwram_lma + SIZEOF(.iwram)) {
        .iwram0 { PROVIDE_HIDDEN (__iwram_overlay = ABSOLUTE(.)); *(.iwram0 .iwram0.*) *.iwram0.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram1 { *(.iwram1 .iwram1.*) *.iwram1.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram2 { *(.iwram2 .iwram2.*) *.iwram2.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram3 { *(.iwram3 .iwram3.*) *.iwram3.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram4 { *(.iwram4 .iwram4.*) *.iwram4.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram5 { *(.iwram5 .iwram5.*) *.iwram5.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram6 { *(.iwram6 .iwram6.*) *.iwram6.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram7 { *(.iwram7 .iwram7.*) *.iwram7.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram8 { *(.iwram8 .iwram8.*) *.iwram8.*(.text .text.* .data .data.*) . = ALIGN(4); }
        .iwram9 { *(.iwram9 .iwram9.*) *.iwram9.*(.text .text.* .data .data.*) . = ALIGN(4); }
    } > iwram

    PROVIDE_HIDDEN (__iwram_lma_end = ALIGN(__iwram_lma + (. - __iwram_start), 4));

    /* Block starting symbol */

    .bss (NOLOAD) : ALIGN(4) {
        PROVIDE_HIDDEN (__bss_start = ABSOLUTE(.));
        EXCLUDE_FILE (*__atexit.* *__call_atexit.* *impure.* *lock.* *on_exit_args.*) *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(4);
        PROVIDE_HIDDEN (__bss_end = ABSOLUTE(.));
    } > iwram

    PROVIDE_HIDDEN (__iwram_end = __bss_end);

    .stack : {
        ASSERT (__iwram_end <= (__sp_usr - __sp_usr_reserve), "IWRAM sections overlap with reserved stack");
    }

    PROVIDE_HIDDEN (__ewram_end = ALIGN(__iwram_lma_end, 4));
    __ewram_lma_end = ALIGN(__ewram_lma + (__ewram_end - __ewram_start), 4);
}
