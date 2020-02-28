OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

MEMORY {
	rom	   : ORIGIN = 0x08000000, LENGTH = 32M
	iwram  : ORIGIN = 0x03000000, LENGTH = 32K
	ewram	 : ORIGIN = 0x02000000, LENGTH = 256K
}

__rom_start	  =	ORIGIN(rom);
__iwram_start = ORIGIN(iwram);
__iwram_top   =	ORIGIN(iwram) + LENGTH(iwram);
__ewram_start =	ORIGIN(ewram);
__ewram_top   =	ORIGIN(ewram) + LENGTH(ewram); /* Heap end */
__sp_irq	    =	__iwram_top - 0x60; /* IRQ stack */
__sp_usr	    =	__sp_irq - 0xa0; /* User stack */

SECTIONS {
	. = __rom_start;

  .crt0 : {
    KEEP (*(.crt0))
    . = ALIGN(4);
  } >rom

  .preinit_array : {
		KEEP (*(.preinit_array))
    . = ALIGN(4);
	} >rom

  .init : {
    KEEP (*(.init))
    . = ALIGN(4);
  } >rom

  .init_array : {
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array))
    . = ALIGN(4);
  } >rom

  .fini : {
    KEEP (*(.fini))
    . = ALIGN(4);
  } >rom

  .fini_array : {
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    . = ALIGN(4);
  } >rom

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
}
