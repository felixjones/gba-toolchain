OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
  iwram : ORIGIN = 0x03000000, LENGTH = 32K
  ewram : ORIGIN = 0x02000000, LENGTH = 256K
}

__iwram_start = ORIGIN(iwram);
__iwram_top   = ORIGIN(iwram) + LENGTH(iwram);
__ewram_start = ORIGIN(ewram);
__ewram_top   = ORIGIN(ewram) + LENGTH(ewram); /* Heap end */
__sp_irq      = __iwram_top - 0x60; /* IRQ stack */
__sp_usr      = __sp_irq - 0xa0; /* User stack */

SECTIONS {
  . = __ewram_start;

  .crt0 : {
    KEEP (*(.crt0))
    . = ALIGN(4);
  } >ewram

  .preinit_array : {
    __preinit_array_start = ABSOLUTE(.);
    KEEP (*(.preinit_array))
    __preinit_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >ewram

  .init : {
    KEEP (*(.init))
    . = ALIGN(4);
  } >ewram

  .init_array : {
    __init_array_start = ABSOLUTE(.);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    __init_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >ewram

  .fini : {
    KEEP (*(.fini))
    . = ALIGN(4);
  } >ewram

  .fini_array : {
    __fini_array_start = ABSOLUTE(.);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    __fini_array_end = ABSOLUTE(.);
    . = ALIGN(4);
  } >ewram

  /* Unwinding (C++ exceptions) */
  .ARM.extab : ALIGN(4) {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } >ewram

  . = ALIGN(4);

  __exidx_start = .;
  .ARM.exidx : ALIGN(4) {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } >ewram
  __exidx_end = .;

  .ctors : {
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
    . = ALIGN(4);
  } >ewram

  .dtors : {
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o ) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))
    . = ALIGN(4);
  } >ewram

  .eh_frame : {
    KEEP (*(.eh_frame))
    . = ALIGN(4);
  } >ewram

  .text : {
    *(EXCLUDE_FILE (*.iwram.* *.iwram[0-9].*) .text*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t*)
    *(.glue_7t) *(.glue_7)
  } >ewram

  .rodata : {
    *(.rodata)
    *(.rodata.*)
    *(.gnu.linkonce.r*)
    . = ALIGN(4);
  } >ewram

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
  } >iwram

  __iwram0_cpuset_copy = ((__iwram0_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram1_cpuset_copy = ((__iwram1_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram2_cpuset_copy = ((__iwram2_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram3_cpuset_copy = ((__iwram3_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram4_cpuset_copy = ((__iwram4_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram5_cpuset_copy = ((__iwram5_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram6_cpuset_copy = ((__iwram6_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram7_cpuset_copy = ((__iwram7_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram8_cpuset_copy = ((__iwram8_end - __iwram_overlay) / 4) | (1 << 26);
  __iwram9_cpuset_copy = ((__iwram9_end - __iwram_overlay) / 4) | (1 << 26);

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

  __ewram_end = .;

  /*
  ====================
    crt0.s CpuSet
  ====================
  */

  __iwram_cpuset_copy = ((__iwram_end - __iwram_start) / 4) | (1 << 26);
  __bss_cpuset_fill = ((__bss_end - __bss_start) / 4) | (5 << 24);
  __data_cpuset_copy = ((__data_end - __data_start) / 4) | (1 << 26);

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
