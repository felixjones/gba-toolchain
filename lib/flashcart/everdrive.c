#include "everdrive.h"

#define SECTION_EWRAM_DATA __attribute__((section(".ewram.data")))

typedef struct everdrive_context {
    uint16_t cart_cfg;
    uint8_t sd_cfg;
    uint8_t card_type;
    uint32_t disk_addr;
    uint8_t sd_resp_buff[18];
} everdrive_context;

static everdrive_context * _ctx SECTION_EWRAM_DATA = NULL;

#define WAIT    ( 2048 )

#define DISK_ERR_INIT           ( 0xc0 )
#define DISK_ERR_RD1            ( 0xd2 )
#define DISK_ERR_RD2            ( 0xd3 )
#define DISK_ERR_WR1            ( 0xd4 )
#define DISK_ERR_WR2            ( 0xd5 )
#define DISK_ERR_WR3            ( 0xd6 )
#define DISK_ERR_WR4            ( 0xd7 )
#define DISK_ERR_WR5            ( 0xd8 )
#define DISK_ERR_CMD_TIMEOUT    ( 0xd9 )
#define DISK_ERR_CRC_ERROR      ( 0xda )
#define DISK_ERR_CLOSE_RW1      ( 0xdb )
#define DISK_ERR_CLOSE_RW2      ( 0xdc )

#define SECTION_BOOTCHECK __attribute__((section(".everdrive._everdrive_bootcheck"), unused))

static int _everdrive_cfg_default() {
    extern int __rom_start[];
    extern int __rom_end[];
    const size_t romSize = ( uintptr_t ) __rom_end - ( uintptr_t ) __rom_start;
    if ( romSize > 0x1000000 ) {
        return CFG_DEFAULT | CFG_BIG_ROM;
    }
    return CFG_DEFAULT;
}

int SECTION_BOOTCHECK _everdrive_bootcheck() {
    static const volatile int * const rom_title = ( const volatile int * ) 0x080000a0;
    static const int * const everdrive_title = ( const int * ) "BOOT-1\0\0\0\0\0\0EDGB";

    REG_KEY = EVERDRIVE_KEY;
    REG_CFG = CFG_EVERDRIVE_UNLOCK;

    for ( int i = 0; i < 4; ++i ) {
        if ( rom_title[i] != everdrive_title[i] ) {
            return 0;
        }
    }

    REG_CFG = _everdrive_cfg_default();
    return 1;
}

static void _everdrive_sd_speed( uint8_t speed );
static void _everdrive_sd_mode( uint8_t mode );
static void _everdrive_sd_dat_wr( uint8_t data );
static int _everdrive_cmd_sd( uint8_t cmd, uint32_t arg );

void * _sbrk( intptr_t increment );

int _everdrive_init() {
    // _sbrk the everdrive context
    _ctx = _sbrk( sizeof( everdrive_context ) );

    // BIOS init
    REG_KEY = EVERDRIVE_KEY;
    REG_CFG = _ctx->cart_cfg = _everdrive_cfg_default() | CFG_EVERDRIVE_UNLOCK;
    REG_SD_CFG = _ctx->sd_cfg = 0;

    // disk init
    _ctx->card_type = 0;

    _everdrive_sd_speed( SD_SPD_LO );

    _everdrive_sd_mode( SD_MODE8 );

    for ( int ii = 0; ii < 40; ++ii ) {
        _everdrive_sd_dat_wr( 0xff );
    }
    _everdrive_cmd_sd( CMD0, 0x1aa );

    for ( int ii = 0; ii < 40; ++ii ) {
        _everdrive_sd_dat_wr( 0xff );
    }
    int resp = _everdrive_cmd_sd( CMD8, 0x1aa );

    if ( resp != 0 && resp != DISK_ERR_CMD_TIMEOUT ) {
        return DISK_ERR_INIT + 0;
    }
    if ( resp == 0 ) {
        _ctx->card_type |= SD_V2;
    }

    int timeout;
    if ( _ctx->card_type == SD_V2 ) {
        for ( timeout = 0; timeout < WAIT; ++timeout ) {
            resp = _everdrive_cmd_sd( CMD55, 0 );
            if ( resp ) {
                return DISK_ERR_INIT + 1;
            }
            if ( ( _ctx->sd_resp_buff[3] & 0x1 ) != 1 ) {
                continue;
            }
            _everdrive_cmd_sd( CMD41, 0x40300000 );
            if ( ( _ctx->sd_resp_buff[1] & 0x80 ) == 0 ) {
                continue;
            }
            break;
        }
    } else {
        timeout = 0;
        do {
            resp = _everdrive_cmd_sd( CMD55, 0 );
            if ( resp ) {
                return DISK_ERR_INIT + 2;
            }
            resp = _everdrive_cmd_sd( CMD41, 0x40300000 );
            if ( resp ) {
                return DISK_ERR_INIT + 3;
            }
        } while ( _ctx->sd_resp_buff[1] < 1 && timeout++ < WAIT );
    }

    if ( timeout == WAIT ) {
        return DISK_ERR_INIT + 4;
    }

    if ( ( _ctx->sd_resp_buff[1] & 0x40 ) && _ctx->card_type != 0 ) {
        _ctx->card_type |= SD_HC;
    }

    resp = _everdrive_cmd_sd( CMD2, 0 );
    if ( resp ) {
        return DISK_ERR_INIT + 5;
    }

    resp = _everdrive_cmd_sd( CMD3, 0 );
    if ( resp ) {
        return DISK_ERR_INIT + 6;
    }

    _everdrive_cmd_sd( CMD7, 0 );

    const uint32_t rca = ( _ctx->sd_resp_buff[1] << 24 ) | ( _ctx->sd_resp_buff[2] << 16 ) | ( _ctx->sd_resp_buff[3] << 8 ) | ( _ctx->sd_resp_buff[4] << 0 );

    resp = _everdrive_cmd_sd( CMD9, rca );
    if ( resp ) {
        return DISK_ERR_INIT + 7;
    }

    resp = _everdrive_cmd_sd( CMD7, rca );
    if ( resp ) {
        return DISK_ERR_INIT + 8;
    }

    resp = _everdrive_cmd_sd( CMD55, rca );
    if ( resp ) {
        return DISK_ERR_INIT + 9;
    }

    resp = _everdrive_cmd_sd( CMD6, 2 );
    if ( resp ) {
        return DISK_ERR_INIT + 10;
    }

    _everdrive_sd_speed( SD_SPD_HI );

    _ctx->disk_addr = ~0;

    return 0;
}

static void _everdrive_sd_speed( uint8_t speed ) {
    _ctx->sd_cfg &= ~SD_SPD_BITS;
    _ctx->sd_cfg |= speed & SD_SPD_BITS;
    REG_SD_CFG = _ctx->sd_cfg;
}

static void _everdrive_sd_mode( uint8_t mode ) {
    _ctx->sd_cfg &= ~SD_MODE_BITS;
    _ctx->sd_cfg |= mode & SD_MODE_BITS;
    REG_SD_CFG = _ctx->sd_cfg;
}

static void _everdrive_sd_dat_wr( uint8_t data ) {
    REG_SD_DAT = 0xff00 | data;
    while ( REG_STATUS & STAT_SD_BUSY );
}

static int _everdrive_get_resp_type_sd( uint8_t cmd );
static uint32_t _everdrive_crc7( uint8_t * buff, uint32_t len );
static void _everdrive_sd_cmd_wr( uint8_t data );
static uint8_t _everdrive_sd_cmd_rd();
static uint8_t _everdrive_sd_cmd_val();

static int _everdrive_cmd_sd( uint8_t cmd, uint32_t arg ) {
    const int resp_type = _everdrive_get_resp_type_sd( cmd );
    uint8_t buff[6];

    const size_t resp_len = resp_type == R2 ? 17 : 6;
    buff[0] = cmd;
    buff[1] = ( arg >> 24 );
    buff[2] = ( arg >> 16 );
    buff[3] = ( arg >> 8 );
    buff[4] = arg;
    uint32_t crc = _everdrive_crc7( buff, 5 ) | 1;

    _everdrive_sd_mode( SD_MODE8 );

    _everdrive_sd_cmd_wr( 0xff );
    _everdrive_sd_cmd_wr( cmd );
    _everdrive_sd_cmd_wr( arg >> 24 );
    _everdrive_sd_cmd_wr( arg >> 16 );
    _everdrive_sd_cmd_wr( arg >> 8 );
    _everdrive_sd_cmd_wr( arg );
    _everdrive_sd_cmd_wr( crc );

    if ( cmd == CMD18 ) return 0;

    _everdrive_sd_cmd_rd();
    _everdrive_sd_mode( SD_MODE1 );
    int timeout = 0;
    for ( ;; ) {
        if ( ( _everdrive_sd_cmd_val() & 0xc0 ) == 0 ) break;

        if ( timeout++ == WAIT ) return DISK_ERR_CMD_TIMEOUT;
        _everdrive_sd_cmd_rd();
    }

    _everdrive_sd_mode( SD_MODE8 );

    _ctx->sd_resp_buff[0] = _everdrive_sd_cmd_rd();

    size_t ii;
    for ( ii = 1; ii < resp_len - 1; ++ii) {
        _ctx->sd_resp_buff[ii] = _everdrive_sd_cmd_rd();
    }
    _ctx->sd_resp_buff[ii] = _everdrive_sd_cmd_val();

    if ( resp_type != R3 ) {
        if ( resp_type == R2 ) {
            crc = _everdrive_crc7( _ctx->sd_resp_buff + 1, resp_len - 2 ) | 1;
        } else {
            crc = _everdrive_crc7( _ctx->sd_resp_buff, resp_len - 1 ) | 1;
        }
        if ( crc != _ctx->sd_resp_buff[resp_len - 1] ) {
            return DISK_ERR_CRC_ERROR;
        }
    }

    return 0;
}

static int _everdrive_get_resp_type_sd( uint8_t cmd ) {
    switch (cmd) {
    case CMD3:
        return R6;
    case CMD8:
        return R7;
    case CMD2:
    case CMD9:
        return R2;
    case CMD58:
    case CMD41:
        return R3;
    default:
        return R1;
    }
}

static uint32_t _everdrive_crc7( uint8_t * buff, uint32_t len ) {
    uint32_t crc = 0;
    while ( len-- ) {
        crc ^= *buff++;
        int bit = 8;
        do {
            crc <<= 1;
            if ( crc & 0x100 ) {
                crc ^= 0x12;
            }
        } while ( --bit );
    }
    return ( crc & 0xfe );
}

static void _everdrive_sd_cmd_wr( uint8_t data ) {
    REG_SD_CMD = data;
    while ( REG_STATUS & STAT_SD_BUSY );
}

static uint8_t _everdrive_sd_cmd_rd() {
    uint8_t dat = REG_SD_CMD;
    while ( REG_STATUS & STAT_SD_BUSY );
    return dat;
}

static uint8_t _everdrive_sd_cmd_val() {
    uint8_t dat = REG_SD_VAL;
    return dat;
}

static int _everdrive_close_rw();
static int _everdrive_open_read( uint32_t saddr );
static int _everdrive_sd_dma_rd( void * dst, size_t slen );

int _everdrive_read( uintptr_t sd_addr, void * dst, size_t slen ) {
    int resp;
    if ( sd_addr != _ctx->disk_addr ) {
        resp = _everdrive_close_rw();
        if ( resp ) {
            return resp;
        }
        resp = _everdrive_open_read( sd_addr );
        if ( resp ) {
            return resp;
        }
        _ctx->disk_addr = sd_addr;
    }

    resp = _everdrive_sd_dma_rd( dst, slen );
    if ( resp ) {
        return DISK_ERR_RD2;
    }

    _ctx->disk_addr += slen;

    return 0;
}

static uint8_t _everdrive_sd_dat_rd();

static int _everdrive_close_rw() {
    if ( _ctx->disk_addr == 0xffffffff ) {
        return 0;
    }
    _ctx->disk_addr = ~0;
    int resp = _everdrive_cmd_sd( CMD12, 0 );
    if ( resp ) {
        return DISK_ERR_CLOSE_RW1;
    }

    _everdrive_sd_mode(SD_MODE1);
    _everdrive_sd_dat_rd();
    _everdrive_sd_dat_rd();
    _everdrive_sd_dat_rd();
    _everdrive_sd_mode(SD_MODE2);

    int timeout = 65535;
    while ( --timeout ) {
        if ( _everdrive_sd_dat_rd() == 0xff ) {
            break;
        }
    }
    if ( timeout == 0 ) {
        return DISK_ERR_CLOSE_RW2;
    }

    return 0;
}

static int _everdrive_open_read( uint32_t saddr ) {
    if ( ( _ctx->card_type & SD_HC ) == 0 ) {
        saddr *= 512;
    }

    if ( _everdrive_cmd_sd( CMD18, saddr ) ) {
        return DISK_ERR_RD1;
    }

    return 0;
}

#define DMA_SRC *( ( vu32 * ) 0x40000D4 )
#define DMA_DST *( ( vu32 * ) 0x40000D8 )
#define DMA_LEN *( ( vu16 * ) 0x40000DC )
#define DMA_CTR *( ( vu16 * ) 0x40000DE )

static int _everdrive_sd_wait_f0();

static int _everdrive_sd_dma_rd( void * dst, size_t slen ) {
    uint8_t * dest = dst;
    while ( slen ) {
        if ( _everdrive_sd_wait_f0() != 0 ) {
            return 1;
        }

        DMA_SRC = ( uint32_t ) ADDR_SD_DAT;
        DMA_DST = ( uint32_t ) dest;
        DMA_LEN = 256;
        DMA_CTR = 0x8000;

        while ( ( DMA_CTR & 0x8000 ) != 0 );

        slen--;
        dest += 512;
    }

    return 0;
}

static uint8_t _everdrive_sd_dat_rd() {
    uint8_t dat = REG_SD_DAT >> 8;
    while ( REG_STATUS & STAT_SD_BUSY );
    return dat;
}

static int _everdrive_sd_wait_f0() {
    uint16_t status;

    int mode = SD_MODE4 | SD_WAIT_F0 | SD_STRT_F0;
    for ( int ii = 0; ii < 65000; ++ii ) {
        _everdrive_sd_mode( mode );
        REG_SD_DAT;

        for ( ;; ) {
            status = REG_STATUS;
            if ( ( status & STAT_SD_BUSY ) == 0 ) {
                break;
            }
        }

        if ( ( status & STAT_SDC_TOUT ) == 0 ) {
            return 0;
        }

        mode = SD_MODE4 | SD_WAIT_F0;
    }

    return 1;
}

static void _everdrive_sd_dma_wr( const void * src );
static void _everdrive_crc16_sd_hw( uint16_t * crc_out );

int _everdrive_write( uintptr_t sd_addr, const void * src, size_t slen ) {
    int resp = _everdrive_close_rw();
    if ( resp ) {
        return resp;
    }

    _ctx->disk_addr = sd_addr;
    if ( ( _ctx->card_type & SD_HC ) == 0 ) {
        sd_addr *= 512;
    }

    resp = _everdrive_cmd_sd( CMD25, sd_addr );
    if ( resp ) {
        return DISK_ERR_WR1;
    }

    uint16_t crc16[5];
    const uint8_t * source = src;
    while ( slen-- ) {
        _everdrive_sd_mode( SD_MODE2 );
        _everdrive_sd_dat_wr( 0xff );
        _everdrive_sd_dat_wr( 0xf0 );

        _everdrive_sd_dma_wr( source );
        _everdrive_crc16_sd_hw( crc16 );
        source += 512;

        _everdrive_sd_mode( SD_MODE2 );
        for ( int ii = 0; ii < 4; ++ii ) {
            _everdrive_sd_dat_wr( crc16[ii] >> 8 );
            _everdrive_sd_dat_wr( crc16[ii] & 0xff );
        }

        _everdrive_sd_mode( SD_MODE1 );
        _everdrive_sd_dat_wr( 0xff );

        _everdrive_sd_dat_rd();

        int timeout = 1024;
        while ( ( _everdrive_sd_dat_rd() & 0x1 ) != 0 && --timeout != 0 );
        if ( timeout == 0 ) {
            return DISK_ERR_WR3;
        }
        resp = 0;

        for ( timeout = 0; timeout < 3; ++timeout ) {
            resp <<= 1;
            const uint8_t u = _everdrive_sd_dat_rd();
            resp |= u & 1;
        }
        resp &= 7;

        if ( resp != 0x02 ) {
            if ( resp == 5 ) {
                return DISK_ERR_WR4;
            }
            return DISK_ERR_WR5;
        }

        _everdrive_sd_mode( SD_MODE1 );
        _everdrive_sd_dat_rd();

        timeout = 65535;
        while ( --timeout ) {
            if ( _everdrive_sd_dat_rd() == 0xff ) {
                break;
            }
        }

        if ( timeout == 0 ) {
            return DISK_ERR_WR2;
        }
    }

    resp = _everdrive_close_rw();
    if ( resp ) {
        return resp;
    }

    return 0;
}

static void _everdrive_sd_dma_wr( const void * src ) {
    REG_SD_RAM = 0;
    _everdrive_sd_mode( SD_MODE4 );
    DMA_SRC = ( uint32_t ) src;
    DMA_DST = ( uint32_t ) ADDR_SD_DAT;
    DMA_LEN = 256;
    DMA_CTR = 0x8040;

    while ( ( DMA_CTR & 0x8000 ) != 0 );
}

static void _everdrive_sd_read_crc_ram( void * dst );

static const uint16_t crc_16_table[];

static void _everdrive_crc16_sd_hw( uint16_t * crc_out ) {
    uint16_t crc_table[4];
    uint8_t * buff = ( uint8_t * ) _sbrk( 512 );
    _everdrive_sd_read_crc_ram( buff );

    for ( int i = 0; i < 4; i++ ) {
        crc_table[i] = 0;
    }

    uint8_t * data_ptr0 = &buff[0];
    uint8_t * data_ptr1 = &buff[128];
    uint8_t * data_ptr2 = &buff[256];
    uint8_t * data_ptr3 = &buff[384];

    uint16_t tmp;
    for ( int i = 0; i < 128; i++ ) {
        tmp = crc_table[0];
        crc_table[0] = crc_16_table[( tmp >> 8 ) ^ *data_ptr0++];
        crc_table[0] = crc_table[0] ^ ( tmp << 8 );

        tmp = crc_table[1];
        crc_table[1] = crc_16_table[( tmp >> 8 ) ^ *data_ptr1++];
        crc_table[1] = crc_table[1] ^ ( tmp << 8 );

        tmp = crc_table[2];
        crc_table[2] = crc_16_table[( tmp >> 8 ) ^ *data_ptr2++];
        crc_table[2] = crc_table[2] ^ ( tmp << 8 );

        tmp = crc_table[3];
        crc_table[3] = crc_16_table[( tmp >> 8 ) ^ *data_ptr3++];
        crc_table[3] = crc_table[3] ^ ( tmp << 8 );
    }

    for ( int i = 0; i < 4; ++i ) {
        for ( int j = 0; j < 16; ++j ) {
            crc_out[3 - i] >>= 1;
            crc_out[3 - i] |= ( crc_table[j % 4] & 1 ) << 15;
            crc_table[j % 4] >>= 1;
        }
    }

    _sbrk( -512 );
}

static void _everdrive_sd_read_crc_ram( void * dst ) {
    REG_SD_RAM = 0;
    DMA_SRC = ( uint32_t ) ADDR_SD_RAM;
    DMA_DST = ( uint32_t ) dst;
    DMA_LEN = 256;
    DMA_CTR = 0x8100;

    while ( ( DMA_CTR & 0x8000 ) != 0 );
}

static const uint16_t crc_16_table[] = {
        0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50A5, 0x60C6, 0x70E7,
        0x8108, 0x9129, 0xA14A, 0xB16B, 0xC18C, 0xD1AD, 0xE1CE, 0xF1EF,
        0x1231, 0x0210, 0x3273, 0x2252, 0x52B5, 0x4294, 0x72F7, 0x62D6,
        0x9339, 0x8318, 0xB37B, 0xA35A, 0xD3BD, 0xC39C, 0xF3FF, 0xE3DE,
        0x2462, 0x3443, 0x0420, 0x1401, 0x64E6, 0x74C7, 0x44A4, 0x5485,
        0xA56A, 0xB54B, 0x8528, 0x9509, 0xE5EE, 0xF5CF, 0xC5AC, 0xD58D,
        0x3653, 0x2672, 0x1611, 0x0630, 0x76D7, 0x66F6, 0x5695, 0x46B4,
        0xB75B, 0xA77A, 0x9719, 0x8738, 0xF7DF, 0xE7FE, 0xD79D, 0xC7BC,
        0x48C4, 0x58E5, 0x6886, 0x78A7, 0x0840, 0x1861, 0x2802, 0x3823,
        0xC9CC, 0xD9ED, 0xE98E, 0xF9AF, 0x8948, 0x9969, 0xA90A, 0xB92B,
        0x5AF5, 0x4AD4, 0x7AB7, 0x6A96, 0x1A71, 0x0A50, 0x3A33, 0x2A12,
        0xDBFD, 0xCBDC, 0xFBBF, 0xEB9E, 0x9B79, 0x8B58, 0xBB3B, 0xAB1A,
        0x6CA6, 0x7C87, 0x4CE4, 0x5CC5, 0x2C22, 0x3C03, 0x0C60, 0x1C41,
        0xEDAE, 0xFD8F, 0xCDEC, 0xDDCD, 0xAD2A, 0xBD0B, 0x8D68, 0x9D49,
        0x7E97, 0x6EB6, 0x5ED5, 0x4EF4, 0x3E13, 0x2E32, 0x1E51, 0x0E70,
        0xFF9F, 0xEFBE, 0xDFDD, 0xCFFC, 0xBF1B, 0xAF3A, 0x9F59, 0x8F78,
        0x9188, 0x81A9, 0xB1CA, 0xA1EB, 0xD10C, 0xC12D, 0xF14E, 0xE16F,
        0x1080, 0x00A1, 0x30C2, 0x20E3, 0x5004, 0x4025, 0x7046, 0x6067,
        0x83B9, 0x9398, 0xA3FB, 0xB3DA, 0xC33D, 0xD31C, 0xE37F, 0xF35E,
        0x02B1, 0x1290, 0x22F3, 0x32D2, 0x4235, 0x5214, 0x6277, 0x7256,
        0xB5EA, 0xA5CB, 0x95A8, 0x8589, 0xF56E, 0xE54F, 0xD52C, 0xC50D,
        0x34E2, 0x24C3, 0x14A0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
        0xA7DB, 0xB7FA, 0x8799, 0x97B8, 0xE75F, 0xF77E, 0xC71D, 0xD73C,
        0x26D3, 0x36F2, 0x0691, 0x16B0, 0x6657, 0x7676, 0x4615, 0x5634,
        0xD94C, 0xC96D, 0xF90E, 0xE92F, 0x99C8, 0x89E9, 0xB98A, 0xA9AB,
        0x5844, 0x4865, 0x7806, 0x6827, 0x18C0, 0x08E1, 0x3882, 0x28A3,
        0xCB7D, 0xDB5C, 0xEB3F, 0xFB1E, 0x8BF9, 0x9BD8, 0xABBB, 0xBB9A,
        0x4A75, 0x5A54, 0x6A37, 0x7A16, 0x0AF1, 0x1AD0, 0x2AB3, 0x3A92,
        0xFD2E, 0xED0F, 0xDD6C, 0xCD4D, 0xBDAA, 0xAD8B, 0x9DE8, 0x8DC9,
        0x7C26, 0x6C07, 0x5C64, 0x4C45, 0x3CA2, 0x2C83, 0x1CE0, 0x0CC1,
        0xEF1F, 0xFF3E, 0xCF5D, 0xDF7C, 0xAF9B, 0xBFBA, 0x8FD9, 0x9FF8,
        0x6E17, 0x7E36, 0x4E55, 0x5E74, 0x2E93, 0x3EB2, 0x0ED1, 0x1EF0
};
