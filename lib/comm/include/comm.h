#ifndef LIBCOMM_COMM_H
#define LIBCOMM_COMM_H

#include <stddef.h>

#define MB_ERR_PALETTE      ( 0x1 << 0 )
#define MB_ERR_NOT_SERVER   ( 0x2 << 0 )

#define MB_ERR_CLIENT( X )                  ( 0x7 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )
#define MB_ERR_CLIENT_STAGE_HEADER( X )     ( 0x1 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )
#define MB_ERR_CLIENT_BAD_HEADER( X )       ( 0x2 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )
#define MB_ERR_CLIENT_ACK_HEADER( X )       ( 0x3 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )
#define MB_ERR_CLIENT_STAGE_PALETTE( X )    ( 0x4 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )
#define MB_ERR_CLIENT_ACK_PALETTE( X )      ( 0x5 << ( 2 + ( ( ( X ) - 1 ) * 3 ) ) )

#define MB_ERR_MULTIBOOT    ( 0x1 << 8 )
#define MB_ERR_TIMEOUT( X ) ( 0x3 | ( ( X ) << 9 ) )

#define MB_PAL_FIX( Color )                     ( ( ( Color ) << 1 ) | 0xf1 )
#define MB_PAL_ANIM( Color, Direction, Speed )  ( ( ( ( Color ) << 4 ) & 0x70 ) | ( ( ( Direction ) << 2 ) & 0x8 ) | ( ( ( Speed ) << 1 ) & 0x6 ) | 0x81 )

#define MV_TIMEOUT_CLIENTS( X ) ( ( X ) >> 9 )

#define MB_CLIENT1  ( 0x1 << 1 )
#define MB_CLIENT2  ( 0x1 << 2 )
#define MB_CLIENT3  ( 0x1 << 3 )

#define MB_CLIENT_ALL   ( MB_CLIENT1 | MB_CLIENT2 | MB_CLIENT3 )

#ifdef __cplusplus
extern "C" {
#endif

int __comm_multiboot_send( int clients, const void * rom, size_t length, int palette );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // define LIBCOMM_COMM_H
