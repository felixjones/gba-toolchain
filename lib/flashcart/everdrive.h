#ifndef _FLASHCART_EVERDRIVE_H_
#define _FLASHCART_EVERDRIVE_H_

#include <stddef.h>
#include <stdint.h>

typedef volatile uint32_t vu32;
typedef volatile uint16_t vu16;
typedef volatile uint8_t vu8;
typedef volatile void * vptr;
typedef volatile const void * vcptr;

#define ADDR_SD_DAT      ( 0x9FC0000 + 0x12 )
#define ADDR_SD_RAM      ( 0x9FC0000 + 0x16 )

#define REG_CFG         ( *( vu16 * ) ( 0x9FC0000 + 0x00 ) )
#define REG_STATUS      ( *( vu16 * ) ( 0x9FC0000 + 0x02 ) )
#define REG_FPGA_VER    ( *( vu16 * ) ( 0x9FC0000 + 0x0a ) )
#define REG_SD_CMD      ( *( vu16 * ) ( 0x9FC0000 + 0x10 ) )
#define REG_SD_DAT      ( *( vu16 * ) ( ADDR_SD_DAT ) )
#define REG_SD_CFG      ( *( vu16 * ) ( 0x9FC0000 + 0x14 ) )
#define REG_SD_VAL      ( *( vu16 * ) ( 0x9FC0000 + 0x14 ) )
#define REG_SD_RAM      ( *( vu16 * ) ( ADDR_SD_RAM ) )
#define REG_KEY         ( *( vu16 * ) ( 0x9FC0000 + 0xb4 ) )

#define STAT_SD_BUSY    ( 0x1 << 0 )
#define STAT_SDC_TOUT   ( 0x1 << 1 )

#define EVERDRIVE_KEY   ( 0xa5 )

#define CFG_REGS_ON     ( 0x1 << 0 )
#define CFG_NROM_RAM    ( 0x1 << 1 )
#define CFG_ROM_WE_ON   ( 0x1 << 2 )
#define CFG_AUTO_WE     ( 0x1 << 3 )

#define CFG_SAVE_TYPE_EEPROM    ( 0x1 << 4 )
#define CFG_SAVE_TYPE_SRAM      ( 0x2 << 4 )
#define CFG_SAVE_TYPE_FLASH64K  ( 0x4 << 4 )
#define CFG_SAVE_TYPE_FLASH128K ( 0x5 << 4 )

#define CFG_SRAM_BANK0  ( 0x0 << 7 )
#define CFG_SRAM_BANK1  ( 0x1 << 7 )
#define CFG_SRAM_BANK2  ( 0x2 << 7 )
#define CFG_SRAM_BANK3  ( 0x3 << 7 )

#define CFG_RTC_ON      ( 0x1 << 9 )
#define CFG_ROM_BANK    ( 0x1 << 10 )
#define CFG_BIG_ROM     ( 0x1 << 11 )

#if ( __gba_save_id == 1 )
#   define DEFAULT_SAVE_TYPE    CFG_SAVE_TYPE_EEPROM
#elif ( __gba_save_id == 2 )
#   define DEFAULT_SAVE_TYPE    CFG_SAVE_TYPE_SRAM
#elif ( __gba_save_id == 3 )
#   define DEFAULT_SAVE_TYPE    CFG_SAVE_TYPE_FLASH64K
#elif ( __gba_save_id == 4 )
#   define DEFAULT_SAVE_TYPE    CFG_SAVE_TYPE_FLASH128K
#else
#   define DEFAULT_SAVE_TYPE    ( 0 )
#endif

#define CFG_EVERDRIVE_UNLOCK    ( CFG_REGS_ON | CFG_ROM_WE_ON )
#define CFG_DEFAULT             ( CFG_NROM_RAM | DEFAULT_SAVE_TYPE | CFG_RTC_ON )

#define SD_SPD_LO   ( 0x0 << 0 )
#define SD_SPD_HI   ( 0x1 << 0 )
#define SD_SPD_BITS ( 0x1 << 0 )

#define SD_MODE1        ( 0x0 << 1 )
#define SD_MODE2        ( 0x1 << 1 )
#define SD_MODE4        ( 0x2 << 1 )
#define SD_MODE8        ( 0x3 << 1 )
#define SD_MODE_BITS    ( 0xf << 1 )

#define SD_WAIT_F0  ( 0x1 << 3 )
#define SD_STRT_F0  ( 0x1 << 4 )

#define CMD0    ( 0x40 )
#define CMD1    ( 0x41 )
#define CMD2    ( 0x42 )
#define CMD3    ( 0x43 )
#define CMD6    ( 0x46 )
#define CMD7    ( 0x47 )
#define CMD8    ( 0x48 )
#define CMD9    ( 0x49 )
#define CMD12   ( 0x4C )
#define CMD17   ( 0x51 )
#define CMD18   ( 0x52 )
#define CMD24   ( 0x58 )
#define CMD25   ( 0x59 )
#define CMD41   ( 0x69 )
#define CMD55   ( 0x77 )
#define CMD58   ( 0x7A )

#define R1  ( 1 )
#define R2  ( 2 )
#define R3  ( 3 )
#define R6  ( 6 )
#define R7  ( 7 )

#define SD_HC   ( 0x1 << 0 )
#define SD_V2   ( 0x1 << 1 )

int _everdrive_init();
int _everdrive_read( uintptr_t sd_addr, void * dst, size_t slen );
int _everdrive_write( uintptr_t sd_addr, const void * src, size_t slen );

#endif // define _FLASHCART_EVERDRIVE_H_
