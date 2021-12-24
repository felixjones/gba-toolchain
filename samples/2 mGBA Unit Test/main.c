/*
===============================================================================

 Sample mGBA unit test

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <tonc.h>

#define MGBA_LOG_FATAL 0
#define MGBA_LOG_ERROR 1
#define MGBA_LOG_WARN 2
#define MGBA_LOG_INFO 3
#define MGBA_LOG_DEBUG 4

#define REG_DEBUG_ENABLE ( ( volatile unsigned short * ) 0x4FFF780 )
#define REG_DEBUG_FLAGS ( ( volatile unsigned short * ) 0x4FFF700 )
#define REG_DEBUG_STRING ( ( char * ) 0x4FFF600 )

void mgba_printf( int level, const char * ptr, ... ) {
    level &= 0x7;
    va_list args;
    va_start( args, ptr );
    vsnprintf( REG_DEBUG_STRING, 0x100, ptr, args );
    va_end( args );
    *REG_DEBUG_FLAGS = level | 0x100;
}

int mgba_open() {
    *REG_DEBUG_ENABLE = 0xC0DE;
    return *REG_DEBUG_ENABLE == 0x1DEA;
}

void mgba_close() {
    *REG_DEBUG_ENABLE = 0;
}

#define SRAM_TEST_STRING ( ( const char * ) 0xE000000 )

int main() {
    mgba_open();

    // Figure out what test we are running
    if ( memcmp( "hello", SRAM_TEST_STRING, 5 ) == 0 ) {
        // mGBA log test
        mgba_printf( MGBA_LOG_DEBUG, "Hello, mGBA!" );
    } else if ( memcmp( "bios_div", SRAM_TEST_STRING, 8 ) == 0 ) {
        // BIOS division test
        const s32 divisionResult = Div( 21, 7 );
        mgba_printf( MGBA_LOG_DEBUG, "BIOS div is %d", divisionResult );
    } else {
        mgba_printf( MGBA_LOG_ERROR, "No tests being ran" );
    }

    irq_init( NULL );
    irq_enable( II_VBLANK );
    mgba_close();

    while ( 1 ) {
        VBlankIntrWait();
    }
}
