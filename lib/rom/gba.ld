OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
  rom   : ORIGIN = 0x08000000, LENGTH = 32M
  iwram : ORIGIN = 0x03000000, LENGTH = 32K
  ewram : ORIGIN = 0x02000000, LENGTH = 256K
}

__rom_start   = ORIGIN(rom);
__iwram_start = ORIGIN(iwram);
__iwram_top   = ORIGIN(iwram) + LENGTH(iwram);
__ewram_start = ORIGIN(ewram);
__ewram_top   = ORIGIN(ewram) + LENGTH(ewram); /* Heap end */
__sp_irq      = __iwram_top - 0x60; /* IRQ stack */
__sp_usr      = __sp_irq - 0xa0; /* User stack */

SECTIONS {
  . = __rom_start;

  .crt0 : {
    KEEP (*(.crt0))
    . = ALIGN(4);
  } >rom

  .preinit_array : {
    __preinit_array_start = ABSOLUTE(.);
    KEEP (*(.preinit_array))
    __preinit_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >rom

  .init : {
    KEEP (*(.init))
    . = ALIGN(4);
  } >rom

  .init_array : {
    __init_array_start = ABSOLUTE(.);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    __init_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >rom

  .fini : {
    KEEP (*(.fini))
    . = ALIGN(4);
  } >rom

  .fini_array : {
    __fini_array_start = ABSOLUTE(.);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    __fini_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >rom

  /* Unwinding (C++ exceptions) */
  .ARM.extab : ALIGN(4) {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } >rom

  . = ALIGN(4);

  __exidx_start = .;
  .ARM.exidx : ALIGN(4) {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } >rom
  __exidx_end = .;

  .ctors : {
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
    . = ALIGN(4);
  } >rom

  .dtors : {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
    . = ALIGN(4);
  } >rom

  .eh_frame : {
    KEEP (*(.eh_frame))
    . = ALIGN(4);
  } >rom

  .text : {
    *(EXCLUDE_FILE (*.iwram.* *.ewram.* *.iwram[0-9].* *.ewram[0-9].*) .text*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t*)
    *(.glue_7t) *(.glue_7)
  } >rom

  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r*)
    . = ALIGN(4);
  } >rom

  /*
  ====================
    iwram
  ====================
  */

  /* IWRAM load memory address (source) */
  __iwram_lma = .;

  .iwram __iwram_start : AT (__iwram_lma) {
    *(.iwram .iwram*)
    *iwram.*(.text* .data*)
    . = ALIGN(4);
    __iwram_end = ABSOLUTE(.);
  } >iwram

  .bss (NOLOAD) : {
    __bss_start = ABSOLUTE(.);
    *(.dynbss)
    *(.bss)
    *(.bss.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = ABSOLUTE(.);
  } >iwram

  /* data load memory address (source) */
  __data_lma = __iwram_lma + SIZEOF(.iwram);

  .data : AT (__data_lma) {
    __data_start = ABSOLUTE(.);
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d*)
    SORT(CONSTRUCTORS)
    . = ALIGN(4);
    __data_end = ABSOLUTE(.);
  } >iwram

  /*
  ====================
    iwram overlays
  ====================
  */

  __iwram_overlay_lma = __data_lma + SIZEOF(.data);

  OVERLAY : NOCROSSREFS AT (__iwram_overlay_lma) {
    .iwram0 {
      __iwram_overlay = ABSOLUTE(.);
      *(.iwram0 .iwram0*) *iwram0.*(.text* .data*) . = ALIGN(4);
      __iwram0_end = ABSOLUTE(.);
      __iwram0_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram1 {
      *(.iwram1 .iwram1*) *iwram1.*(.text* .data*) . = ALIGN(4);
      __iwram1_end = ABSOLUTE(.);
      __iwram1_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram2 {
      *(.iwram2 .iwram2*) *iwram2.*(.text* .data*) . = ALIGN(4);
      __iwram2_end = ABSOLUTE(.);
      __iwram2_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram3 {
      *(.iwram3 .iwram3*) *iwram3.*(.text* .data*) . = ALIGN(4);
      __iwram3_end = ABSOLUTE(.);
      __iwram3_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram4 {
      *(.iwram4 .iwram4*) *iwram4.*(.text* .data*) . = ALIGN(4);
      __iwram4_end = ABSOLUTE(.);
      __iwram4_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram5 {
      *(.iwram5 .iwram5*) *iwram5.*(.text* .data*) . = ALIGN(4);
      __iwram5_end = ABSOLUTE(.);
      __iwram5_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram6 {
      *(.iwram6 .iwram6*) *iwram6.*(.text* .data*) . = ALIGN(4);
      __iwram6_end = ABSOLUTE(.);
      __iwram6_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram7 {
      *(.iwram7 .iwram7*) *iwram7.*(.text* .data*) . = ALIGN(4);
      __iwram7_end = ABSOLUTE(.);
      __iwram7_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram8 {
      *(.iwram8 .iwram8*) *iwram8.*(.text* .data*) . = ALIGN(4);
      __iwram8_end = ABSOLUTE(.);
      __iwram8_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
    .iwram9 {
      *(.iwram9 .iwram9*) *iwram9.*(.text* .data*) . = ALIGN(4);
      __iwram9_end = ABSOLUTE(.);
      __iwram9_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
    }
  } >iwram

  __iwram_overlay_size = __load_stop_iwram0 - __load_start_iwram0 +
    __load_stop_iwram1 - __load_start_iwram1 +
    __load_stop_iwram2 - __load_start_iwram2 +
    __load_stop_iwram3 - __load_start_iwram3 +
    __load_stop_iwram4 - __load_start_iwram4 +
    __load_stop_iwram5 - __load_start_iwram5 +
    __load_stop_iwram6 - __load_start_iwram6 +
    __load_stop_iwram7 - __load_start_iwram7 +
    __load_stop_iwram8 - __load_start_iwram8 +
    __load_stop_iwram9 - __load_start_iwram9;

  __iwram_overlay_end = __iwram_overlay + __iwram_overlay_size;

  /*
  ====================
    ewram
  ====================
  */

  /* EWRAM load memory address (source) */
  __ewram_lma = __iwram_overlay_lma + __iwram_overlay_size;

  .ewram __ewram_start : AT (__ewram_lma) {
    *(.ewram .ewram*)
    *ewram.*(.text* .data*)
    . = ALIGN(4);
    __ewram_end = ABSOLUTE(.);
  } >ewram

  /*
  ====================
    ewram overlays
  ====================
  */

  __ewram_overlay_lma = __ewram_lma + SIZEOF(.ewram);

  OVERLAY : NOCROSSREFS AT (__ewram_overlay_lma) {
    .ewram0 {
      __ewram_overlay = ABSOLUTE(.);
      *(.ewram0 .ewram0*) *ewram0.*(.text* .data*) . = ALIGN(4);
      __ewram0_end = ABSOLUTE(.);
      __ewram0_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram1 {
      *(.ewram1 .ewram1*) *ewram1.*(.text* .data*) . = ALIGN(4);
      __ewram1_end = ABSOLUTE(.);
      __ewram1_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram2 {
      *(.ewram2 .ewram2*) *ewram2.*(.text* .data*) . = ALIGN(4);
      __ewram2_end = ABSOLUTE(.);
      __ewram2_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram3 {
      *(.ewram3 .ewram3*) *ewram3.*(.text* .data*) . = ALIGN(4);
      __ewram3_end = ABSOLUTE(.);
      __ewram3_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram4 {
      *(.ewram4 .ewram4*) *ewram4.*(.text* .data*) . = ALIGN(4);
      __ewram4_end = ABSOLUTE(.);
      __ewram4_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram5 {
      *(.ewram5 .ewram5*) *ewram5.*(.text* .data*) . = ALIGN(4);
      __ewram5_end = ABSOLUTE(.);
      __ewram5_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram6 {
      *(.ewram6 .ewram6*) *ewram6.*(.text* .data*) . = ALIGN(4);
      __ewram6_end = ABSOLUTE(.);
      __ewram6_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram7 {
      *(.ewram7 .ewram7*) *ewram7.*(.text* .data*) . = ALIGN(4);
      __ewram7_end = ABSOLUTE(.);
      __ewram7_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram8 {
      *(.ewram8 .ewram8*) *ewram8.*(.text* .data*) . = ALIGN(4);
      __ewram8_end = ABSOLUTE(.);
      __ewram8_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
    .ewram9 {
      *(.ewram9 .ewram9*) *ewram9.*(.text* .data*) . = ALIGN(4);
      __ewram9_end = ABSOLUTE(.);
      __ewram9_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
    }
  } >ewram

  __ewram_overlay_size = __load_stop_ewram0 - __load_start_ewram0 +
    __load_stop_ewram1 - __load_start_ewram1 +
    __load_stop_ewram2 - __load_start_ewram2 +
    __load_stop_ewram3 - __load_start_ewram3 +
    __load_stop_ewram4 - __load_start_ewram4 +
    __load_stop_ewram5 - __load_start_ewram5 +
    __load_stop_ewram6 - __load_start_ewram6 +
    __load_stop_ewram7 - __load_start_ewram7 +
    __load_stop_ewram8 - __load_start_ewram8 +
    __load_stop_ewram9 - __load_start_ewram9;

  __ewram_overlay_end = __ewram_overlay + __ewram_overlay_size;

  __rom_end = __ewram_overlay_lma + __ewram_overlay_size;

  /*
  ====================
    crt0.s CpuSet
  ====================
  */

  __iwram_cpuset_copy = ((__iwram_end - __iwram_start) / 4) | (1 << 26);
  __bss_cpuset_fill = ((__bss_end - __bss_start) / 4) | (5 << 24);
  __data_cpuset_copy = ((__data_end - __data_start) / 4) | (1 << 26);
  __ewram_cpuset_copy = ((__ewram_end - __ewram_start) / 4) | (1 << 26);

  /*
  ====================
    Debugging
  ====================
  */

  /* DWARF debug sections */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  .debug_ranges   0 : { *(.debug_ranges) }
}
