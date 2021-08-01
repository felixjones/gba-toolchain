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
__everdrive_start = __ewram_top;
__ezflash_start = __ewram_top;
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
    *(EXCLUDE_FILE (*.iwram.* *.ewram.* *.iwram[0-9].* *.ewram[0-9].* *.everdrive.*) .text*)
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

  /*
  ====================
    disk overlays
  ====================
  */

  __disk_overlay_lma = __iwram_overlay_lma + __iwram_overlay_size;

  OVERLAY : NOCROSSREFS AT (__disk_overlay_lma) {
    .disk0 { __disk_overlay = ABSOLUTE(.); *(.disk0 .disk0*) *disk0.*(.text* .data*) . = ALIGN(4); __disk0_end = ABSOLUTE(.); }
    .disk1 { *(.disk1 .disk1*) *disk1.*(.text* .data*) . = ALIGN(4); __disk1_end = ABSOLUTE(.); }
    .disk2 { *(.disk2 .disk2*) *disk2.*(.text* .data*) . = ALIGN(4); __disk2_end = ABSOLUTE(.); }
    .disk3 { *(.disk3 .disk3*) *disk3.*(.text* .data*) . = ALIGN(4); __disk3_end = ABSOLUTE(.); }
    .disk4 { *(.disk4 .disk4*) *disk4.*(.text* .data*) . = ALIGN(4); __disk4_end = ABSOLUTE(.); }
    .disk5 { *(.disk5 .disk5*) *disk5.*(.text* .data*) . = ALIGN(4); __disk5_end = ABSOLUTE(.); }
    .disk6 { *(.disk6 .disk6*) *disk6.*(.text* .data*) . = ALIGN(4); __disk6_end = ABSOLUTE(.); }
  } >iwram

  __disk0_cpuset_copy = ((__disk0_end - __disk_overlay) / 4) | (1 << 26);
  __disk1_cpuset_copy = ((__disk1_end - __disk_overlay) / 4) | (1 << 26);
  __disk2_cpuset_copy = ((__disk2_end - __disk_overlay) / 4) | (1 << 26);
  __disk3_cpuset_copy = ((__disk3_end - __disk_overlay) / 4) | (1 << 26);
  __disk4_cpuset_copy = ((__disk4_end - __disk_overlay) / 4) | (1 << 26);
  __disk5_cpuset_copy = ((__disk5_end - __disk_overlay) / 4) | (1 << 26);
  __disk6_cpuset_copy = ((__disk6_end - __disk_overlay) / 4) | (1 << 26);

  __disk_overlay_size = __load_stop_disk0 - __load_start_disk0 +
      __load_stop_disk1 - __load_start_disk1 +
      __load_stop_disk2 - __load_start_disk2 +
      __load_stop_disk3 - __load_start_disk3 +
      __load_stop_disk4 - __load_start_disk4 +
      __load_stop_disk5 - __load_start_disk5 +
      __load_stop_disk6 - __load_start_disk6;

  __disk_overlay_end = __disk_overlay + __disk_overlay_size;

  /*
  ====================
    ewram
  ====================
  */

  /* EWRAM load memory address (source) */
  __ewram_lma = __disk_overlay_lma + __disk_overlay_size;

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
    .ewram0 { __ewram_overlay = ABSOLUTE(.); *(.ewram0 .ewram0*) *ewram0.*(.text* .data*) . = ALIGN(4); __ewram0_end = ABSOLUTE(.); }
    .ewram1 { *(.ewram1 .ewram1*) *ewram1.*(.text* .data*) . = ALIGN(4); __ewram1_end = ABSOLUTE(.); }
    .ewram2 { *(.ewram2 .ewram2*) *ewram2.*(.text* .data*) . = ALIGN(4); __ewram2_end = ABSOLUTE(.); }
    .ewram3 { *(.ewram3 .ewram3*) *ewram3.*(.text* .data*) . = ALIGN(4); __ewram3_end = ABSOLUTE(.); }
    .ewram4 { *(.ewram4 .ewram4*) *ewram4.*(.text* .data*) . = ALIGN(4); __ewram4_end = ABSOLUTE(.); }
    .ewram5 { *(.ewram5 .ewram5*) *ewram5.*(.text* .data*) . = ALIGN(4); __ewram5_end = ABSOLUTE(.); }
    .ewram6 { *(.ewram6 .ewram6*) *ewram6.*(.text* .data*) . = ALIGN(4); __ewram6_end = ABSOLUTE(.); }
    .ewram7 { *(.ewram7 .ewram7*) *ewram7.*(.text* .data*) . = ALIGN(4); __ewram7_end = ABSOLUTE(.); }
    .ewram8 { *(.ewram8 .ewram8*) *ewram8.*(.text* .data*) . = ALIGN(4); __ewram8_end = ABSOLUTE(.); }
    .ewram9 { *(.ewram9 .ewram9*) *ewram9.*(.text* .data*) . = ALIGN(4); __ewram9_end = ABSOLUTE(.); }
  } >ewram

  __ewram0_cpuset_copy = ((__ewram0_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram1_cpuset_copy = ((__ewram1_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram2_cpuset_copy = ((__ewram2_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram3_cpuset_copy = ((__ewram3_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram4_cpuset_copy = ((__ewram4_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram5_cpuset_copy = ((__ewram5_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram6_cpuset_copy = ((__ewram6_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram7_cpuset_copy = ((__ewram7_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram8_cpuset_copy = ((__ewram8_end - __ewram_overlay) / 4) | (1 << 26);
  __ewram9_cpuset_copy = ((__ewram9_end - __ewram_overlay) / 4) | (1 << 26);

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

  /*
  ====================
    everdrive
  ====================
  */

  /* everdrive load memory address (source) */
  __everdrive_lma = __ewram_overlay_lma + __ewram_overlay_size;

  OVERLAY : NOCROSSREFS AT (__everdrive_lma) {
    .everdrive { __everdrive_start = ABSOLUTE(.); *(.everdrive .everdrive*) *everdrive.*(.text* .data*) . = ALIGN(4); __everdrive_end = ABSOLUTE(.); }
  } >ewram

  __everdrive_size = __load_stop_everdrive - __load_start_everdrive;

  /*
  ====================
    ezflash
  ====================
  */

  /* ezflash load memory address (source) */
  __ezflash_lma = __everdrive_lma + __everdrive_size;

  OVERLAY : NOCROSSREFS AT (__ezflash_lma) {
    .ezflash { __ezflash_start = ABSOLUTE(.); *(.ezflash .ezflash*) *ezflash.*(.text* .data*) . = ALIGN(4); __ezflash_end = ABSOLUTE(.); }
  } >ewram

  __ezflash_size = __load_stop_ezflash - __load_start_ezflash;

  __rom_end = __ezflash_lma + __ezflash_size;

  /*
  ====================
    crt0.s CpuSet
  ====================
  */

  __iwram_cpuset_copy = ((__iwram_end - __iwram_start) / 4) | (1 << 26);
  __bss_cpuset_fill = ((__bss_end - __bss_start) / 4) | (5 << 24);
  __data_cpuset_copy = ((__data_end - __data_start) / 4) | (1 << 26);
  __ewram_cpuset_copy = ((__ewram_end - __ewram_start) / 4) | (1 << 26);
  __everdrive_cpuset_copy = ((__everdrive_end - __everdrive_start) / 4) | (1 << 26);
  __ezflash_cpuset_copy = ((__ezflash_end - __ezflash_start) / 4) | (1 << 26);

  /*
  ====================
    crt0.s System detection
  ====================
  */

  __mgba_debug_enable = 0x04fff780;
  __everdrive_config = 0x09fc0000;
  __everdrive_enable = 0x09fc00b4;

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
