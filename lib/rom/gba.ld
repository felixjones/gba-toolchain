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
    *(EXCLUDE_FILE (*.iwram.* *.ewram.*) .text*)
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
    ewram
  ====================
  */

  /* EWRAM load memory address (source) */
  __ewram_lma = __data_lma + SIZEOF(.data);

  .ewram __ewram_start : AT (__ewram_lma) {
    *(.ewram .ewram*)
    *ewram.*(.text* .data*)
    . = ALIGN(4);
    __ewram_end = ABSOLUTE(.);
  } >ewram

  __rom_end = __ewram_lma + SIZEOF(.ewram);

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
