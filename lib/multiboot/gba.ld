OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
  iwram : ORIGIN = 0x03000000, LENGTH = 32K
  ewram : ORIGIN = 0x02000000, LENGTH = 256K
}

__iwram_start = ORIGIN(iwram) + 0x4;
__iwram_top   = ORIGIN(iwram) + LENGTH(iwram) - 0x4;
__ewram_start = ORIGIN(ewram);
__ewram_top   = ORIGIN(ewram) + LENGTH(ewram); /* Heap end */
__sp_irq      = __iwram_top - 0x60; /* IRQ stack */
__sp_usr      = __sp_irq - 0xa0; /* User stack */
__jt_irq      = ORIGIN(iwram); /* IRQ jump table address */

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
    *(EXCLUDE_FILE (*.iwram*) .text*)
    *(EXCLUDE_FILE (*.ewram*) .text*)
    *(.text)
    *(.text.*)
    *(.stub)
    /* .gnu.warning sections are handled specially by elf32.em.  */
    *(.gnu.warning)
    *(.gnu.linkonce.t*)
    *(.glue_7t) *(.glue_7)
  } >ewram

  .rodata : {
    *(EXCLUDE_FILE (*.iwram*) .rodata*)
    *(.rodata)
    *(.rodata.*)
    *(.ewram.rodata)
    *(.ewram.rodata.*)
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

  __ewram_end = .;

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
