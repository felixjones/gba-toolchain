#include "comm.h"

#include <stdint.h>

void __aeabi_memclr4( void *, size_t n );

typedef volatile uint16_t vu16;
typedef volatile uint32_t vu32;

#define REG_SIOMULTI0   ( *( vu16 * ) 0x4000120 )
#define REG_SIOMULTI1   ( *( vu16 * ) 0x4000122 )
#define REG_SIOMULTI2   ( *( vu16 * ) 0x4000124 )
#define REG_SIOMULTI3   ( *( vu16 * ) 0x4000126 )
#define REG_SIOCNT      ( *( vu16 * ) 0x4000128 )
#define REG_SIOMLT_SEND ( *( vu16 * ) 0x400012A )
#define REG_RCNT        ( *( vu16 * ) 0x4000134 )

#define CLOCK_INTERNAL  ( 0x1 << 0 )
#define MHZ_2           ( 0x1 << 1 )
#define OPPONENT_SO_HI  ( 0x1 << 2 )
#define SIO_START       ( 0x1 << 7 )

#define CHILD1  MB_CLIENT1
#define CHILD2  MB_CLIENT2
#define CHILD3  MB_CLIENT3

#define MB_MODE_MULTI   ( 0x1 << 0 )

struct multi_boot_param {
    uint32_t reserved1[5];
    uint8_t handshake_data;
    uint8_t padding;
    uint16_t handshake_timeout;
    uint8_t probe_count;
    uint8_t client_data[3];
    uint8_t palette_data;
    uint8_t response_bit;
    uint8_t client_bit;
    uint8_t reserved2;
    const void * boot_srcp;
    const void * boot_endp;
    const void * masterp;
    const void * reserved3[3];
    uint32_t system_work2[4];
    uint8_t	sendflag;
    uint8_t	probe_target_bit;
    uint8_t	check_wait;
    uint8_t	server_type;
};

static int __attribute__((naked)) multi_boot( const struct multi_boot_param * param, const int mode ) {
    __asm__ (
#if !defined( __thumb__ )
#error  compile with thumb
#else
        "swi\t%[Swi]\n\t"
        "bx\tlr"
#endif
        :: [Swi]"i"( 0x25 ) : "r0", "r1", "r3"
    );
}

static void __attribute__((naked)) comm_wait( int loops ) {
    __asm__ volatile (
        ".Lloop:\n\t"
#ifdef __clang__
        "subs\tr0, r0, #1\n\t"
#else
        "sub\tr0, r0, #1\n\t"
#endif
        "bne\t.Lloop\n\t"
        "bx\tlr"
        ::: "r0"
    );
}

static void comm_send_multi( int data, int * response );

int __comm_multiboot_send( const int clients, const void * const rom, const size_t length, int palette ) {
    if ( ( palette & 0x81 ) != 0x81 ) {
        return MB_ERR_PALETTE;
    }

    REG_RCNT = 0;
    REG_SIOCNT = CLOCK_INTERNAL | MHZ_2 | ( 0x1 << 13 );

    if ( REG_SIOCNT & OPPONENT_SO_HI ) {
        return MB_ERR_NOT_SERVER;
    }

    int response[4];

    int connectedClients = 0;
    int timeout = 15;
    do {
        int tries = 15;
        do {
            comm_send_multi( 0x6200, response );

            if ( ( response[1] & 0xfff0 ) == 0x7200 ) connectedClients |= ( response[1] & 0xf );
            if ( ( response[2] & 0xfff0 ) == 0x7200 ) connectedClients |= ( response[2] & 0xf );
            if ( ( response[3] & 0xfff0 ) == 0x7200 ) connectedClients |= ( response[3] & 0xf );
        } while ( --tries );

        if ( connectedClients ) {
            break;
        } else {
            comm_wait( 10000 );
        }
    } while ( --timeout );

    if ( !( connectedClients & clients ) ) {
        return MB_ERR_TIMEOUT( connectedClients );
    }

    connectedClients &= clients;

    comm_send_multi( 0x6100 | connectedClients, response );
    int clientErrors = 0;
    if ( ( connectedClients & CHILD1 ) && response[1] != ( 0x7200 | CHILD1 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_HEADER( 1 );
    if ( ( connectedClients & CHILD2 ) && response[2] != ( 0x7200 | CHILD2 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_HEADER( 2 );
    if ( ( connectedClients & CHILD3 ) && response[3] != ( 0x7200 | CHILD3 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_HEADER( 3 );
    if ( clientErrors ) return clientErrors;

    const uint16_t * rom16 = rom;
    for ( int ii = 0; ii < 0x60; ++ii ) {
        comm_send_multi( *rom16++, response );
        clientErrors = 0;
        if ( ( connectedClients & CHILD1 ) && response[1] != ( ( 0x60 - ii ) << 8 | CHILD1 ) ) clientErrors |= MB_ERR_CLIENT_BAD_HEADER( 1 );
        if ( ( connectedClients & CHILD2 ) && response[2] != ( ( 0x60 - ii ) << 8 | CHILD2 ) ) clientErrors |= MB_ERR_CLIENT_BAD_HEADER( 2 );
        if ( ( connectedClients & CHILD3 ) && response[3] != ( ( 0x60 - ii ) << 8 | CHILD3 ) ) clientErrors |= MB_ERR_CLIENT_BAD_HEADER( 3 );
        if ( clientErrors ) return clientErrors;
    }

    comm_send_multi( 0x6200, response );
    clientErrors = 0;
    if ( ( connectedClients & CHILD1 ) && response[1] != CHILD1 ) clientErrors |= MB_ERR_CLIENT_ACK_HEADER( 1 );
    if ( ( connectedClients & CHILD2 ) && response[2] != CHILD2 ) clientErrors |= MB_ERR_CLIENT_ACK_HEADER( 2 );
    if ( ( connectedClients & CHILD3 ) && response[3] != CHILD3 ) clientErrors |= MB_ERR_CLIENT_ACK_HEADER( 3 );
    if ( clientErrors ) return clientErrors;

    comm_send_multi( 0x6200 | connectedClients, response );
    clientErrors = 0;
    if ( ( connectedClients & CHILD1 ) && response[1] != ( 0x7200 | CHILD1 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_PALETTE( 1 );
    if ( ( connectedClients & CHILD2 ) && response[2] != ( 0x7200 | CHILD2 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_PALETTE( 2 );
    if ( ( connectedClients & CHILD3 ) && response[3] != ( 0x7200 | CHILD3 ) ) clientErrors |= MB_ERR_CLIENT_STAGE_PALETTE( 3 );
    if ( clientErrors ) return clientErrors;

    int clientAck = connectedClients;
    uint8_t clientData[4] = { 0x11, 0xff, 0xff, 0xff };
    while ( clientAck ) {
        comm_send_multi( 0x6300 | palette, response );

        if ( ( connectedClients & CHILD1 ) && ( response[1] & 0xff00 ) == 0x7300 ) {
            clientData[1] = response[1];
            clientAck &= ~CHILD1;
        }

        if ( ( connectedClients & CHILD2 ) && ( response[2] & 0xff00 ) == 0x7300 ) {
            clientData[2] = response[2];
            clientAck &= ~CHILD2;
        }

        if ( ( connectedClients & CHILD3 ) && ( response[3] & 0xff00 ) == 0x7300 ) {
            clientData[3] = response[3];
            clientAck &= ~CHILD3;
        }
    }

    clientData[0] += clientData[1] + clientData[2] + clientData[3];
    comm_send_multi( 0x6400 | clientData[0], response );
    clientErrors = 0;
    if ( ( connectedClients & CHILD1 ) && ( response[1] & 0xff00 ) != 0x7300 ) clientErrors |= MB_ERR_CLIENT_ACK_PALETTE( 1 );
    if ( ( connectedClients & CHILD2 ) && ( response[2] & 0xff00 ) != 0x7300 ) clientErrors |= MB_ERR_CLIENT_ACK_PALETTE( 2 );
    if ( ( connectedClients & CHILD3 ) && ( response[3] & 0xff00 ) != 0x7300 ) clientErrors |= MB_ERR_CLIENT_ACK_PALETTE( 3 );
    if ( clientErrors ) return clientErrors;

    struct multi_boot_param mbp;
    __aeabi_memclr4( &mbp, sizeof( mbp ) );

    mbp.handshake_data = clientData[0];
    mbp.client_data[0] = clientData[1];
    mbp.client_data[1] = clientData[2];
    mbp.client_data[2] = clientData[3];
    mbp.palette_data = palette;
    mbp.client_bit = connectedClients;
    mbp.boot_srcp = ( const void * ) rom16;
    mbp.boot_endp = ( const void * ) ( ( uintptr_t ) rom + length );

    if ( multi_boot( &mbp, MB_MODE_MULTI ) ) {
        return MB_ERR_MULTIBOOT;
    }

    return 0;
}

static void comm_send_multi( const int data, int * const response ) {
    REG_SIOMLT_SEND = data;
    REG_SIOCNT |= SIO_START;

    while ( REG_SIOCNT & SIO_START );

    response[0] = REG_SIOMULTI0;
    response[1] = REG_SIOMULTI1;
    response[2] = REG_SIOMULTI2;
    response[3] = REG_SIOMULTI3;
}
