#include "rtc.h"

typedef unsigned short u16;
typedef volatile u16 vu16;

#define GPIO_PORT_DATA        ( *( vu16 * ) 0x080000c4 )
#define GPIO_PORT_DIRECTION   ( *( vu16 * ) 0x080000c6 )
#define GPIO_PORT_READ_ENABLE ( *( vu16 * ) 0x080000c8 )

#define CMD( X )    ( 0x60 | ( ( X ) << 1 ) )
#define CMD_WR( X ) ( CMD( X ) )
#define CMD_RD( X ) ( CMD( X ) | 0x1 )

#define CMD_RESET           ( CMD_WR( 0 ) )
#define CMD_STATUS_READ     ( CMD_RD( 1 ) )
#define CMD_DATETIME_READ   ( CMD_RD( 2 ) )
#define CMD_TIME_READ       ( CMD_RD( 3 ) )

#define CMD_STATUS_WRITE    ( CMD_WR( 1 ) )
#define CMD_DATETIME_WRITE  ( CMD_WR( 2 ) )
#define CMD_TIME_WRITE      ( CMD_WR( 3 ) )

#define RTC_STATUS_INTFE    ( 0x01 )
#define RTC_STATUS_INTME    ( 0x02 )
#define RTC_STATUS_INTAE    ( 0x04 )
#define RTC_STATUS_24HOUR   ( 0x40 )
#define RTC_STATUS_POWER    ( 0x80 )

#define TIME_BIT_AM_PM  ( 0x1 << 23 )
#define TIME_BIT_TEST   ( 0x1 << 7 )

#define TM_YEAR( X )        ( ( ( X ) >> 48 ) & 0xff )
#define TM_YEAR_UNIT( X )   ( ( TM_YEAR( X ) >> 0 ) & 0x0f )

#define TM_MONTH( X )       ( ( ( X ) >> 40 ) & 0xff )
#define TM_MONTH_UNIT( X )  ( ( TM_MONTH( X ) >> 0 ) & 0x0f )

#define TM_DAY( X )       ( ( ( X ) >> 32 ) & 0xff )
#define TM_DAY_UNIT( X )  ( ( TM_DAY( X ) >> 0 ) & 0x0f )

#define TM_WDAY( X )       ( ( ( X ) >> 24 ) & 0xff )
#define TM_WDAY_UNIT( X )  ( ( TM_WDAY( X ) >> 0 ) & 0x0f )

#define TM_HOUR( X )       ( ( ( X ) >> 16 ) & 0xff )
#define TM_HOUR_UNIT( X )  ( ( TM_HOUR( X ) >> 0 ) & 0x0f )

#define TM_MIN( X )       ( ( ( X ) >> 8 ) & 0xff )
#define TM_MIN_UNIT( X )  ( ( TM_MIN( X ) >> 0 ) & 0x0f )

#define TM_SEC( X )       ( ( ( X ) >> 0 ) & 0xff )
#define TM_SEC_UNIT( X )  ( ( TM_SEC( X ) >> 0 ) & 0x0f )

static void rtc_reset();

int __rtc_init() {
    GPIO_PORT_READ_ENABLE = 1;
    int status = __rtc_get_status();
    if ( ( status & RTC_STATUS_POWER ) || ( status & RTC_STATUS_24HOUR ) == 0 ) {
        // Reset (also switches to 24-hour mode)
        rtc_reset();
    }

    const rtc_time time = __rtc_get_time();
    if ( time & TIME_BIT_TEST ) {
        // Reset to leave test mode
        rtc_reset();
    }

    status = __rtc_get_status();

    if ( status & RTC_STATUS_POWER ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EPOWER;
    }

    if ( ( status & RTC_STATUS_24HOUR ) == 0 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_E12HOUR;
    }

    const rtc_tm datetime = __rtc_get_datetime();

    if ( TM_YEAR( datetime ) > 0x9f || TM_YEAR_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EYEAR;
    }

    if ( TM_MONTH( datetime ) == 0 || TM_MONTH( datetime ) > 0x1f || TM_MONTH_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EMON;
    }

    if ( TM_DAY( datetime ) == 0 || TM_DAY( datetime ) > 0x3f || TM_DAY_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EDAY;
    }

    if ( ( TM_WDAY( datetime ) & 0xf8 ) || TM_WDAY_UNIT( datetime ) > 6 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EWDAY;
    }

    if ( TM_HOUR( datetime ) > 0x2f || TM_HOUR_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EHOUR;
    }

    if ( TM_MIN( datetime ) > 0x5f || TM_MIN_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_EMIN;
    }

    if ( TM_SEC( datetime ) > 0x5f || TM_SEC_UNIT( datetime ) > 9 ) {
        GPIO_PORT_READ_ENABLE = 0;
        return RTC_ESEC;
    }

    return 0;
}

static void rtc_write_command( int cmd );
static int rtc_read_data8();

int __rtc_get_status() {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_STATUS_READ );

    GPIO_PORT_DIRECTION = 0x5;

    const int status = rtc_read_data8();

    GPIO_PORT_DATA = 1;
    GPIO_PORT_DATA = 1;

    return status;
}

static void rtc_write_command( const int cmd ) {
    int bit = 7;
    do {
        const int value = ( ( cmd >> bit ) & 1 ) << 1;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x5;
    } while ( bit-- );
}

static int rtc_read_data8() {
    int byte = 0;
    int bit = 0;
    do {
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x5;
        byte |= ( ( GPIO_PORT_DATA & 0x2 ) >> 1 ) << bit;
    } while ( ++bit < 8 );
    return byte;
}

static void rtc_write_data8( int data );

void rtc_reset() {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_RESET );

    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x1;

    // Set initial status
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_STATUS_WRITE );
    rtc_write_data8( RTC_STATUS_24HOUR );

    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x1;
}

static void rtc_write_data8( const int data ) {
    int bit = 0;
    do {
        const int value = ( ( data >> bit ) & 1 ) << 1;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x4;
        GPIO_PORT_DATA = value | 0x5;
    } while ( ++bit < 8 );
}

static int rtc_read_data24();

rtc_time __rtc_get_time() {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_TIME_READ );

    GPIO_PORT_DIRECTION = 0x5;

    const int time = rtc_read_data24() & ~TIME_BIT_AM_PM;

    GPIO_PORT_DATA = 1;
    GPIO_PORT_DATA = 1;

    return time;
}

static int rtc_read_data24() {
    int word = 0;
    int bit = 0;
    do {
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x5;
        word |= ( ( GPIO_PORT_DATA & 0x2 ) >> 1 ) << bit;
    } while ( ++bit < 24 );
    return ( ( word & 0xff0000 ) >> 16 ) | ( ( word & 0xff ) << 16 ) | ( word & 0xff00 );
}

static int rtc_read_data32();

rtc_tm __rtc_get_datetime() {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_DATETIME_READ );

    GPIO_PORT_DIRECTION = 0x5;

    const rtc_tm date = rtc_read_data24();
    const int time = rtc_read_data32() & ~TIME_BIT_AM_PM;

    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x1;

    return ( date << 32 ) | time;
}

static int rtc_read_data32() {
    int word = 0;
    int bit = 0;
    do {
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x4;
        GPIO_PORT_DATA = 0x5;
        word |= ( ( GPIO_PORT_DATA & 0x2 ) >> 1 ) << bit;
    } while ( ++bit < 32 );
    return ( int ) ( ( word & 0xff000000 ) >> 24 ) | ( word << 24 ) | ( ( word & 0xff0000 ) >> 8 ) | ( ( word & 0xff00 ) << 8 );
}

void __rtc_set_time( const rtc_time time ) {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_TIME_WRITE );

    int bytes = 2;
    do {
        rtc_write_data8( ( time >> ( bytes * 8 ) ) & 0xff );
    } while ( bytes-- > 0 );

    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x1;
}

void __rtc_set_datetime( const rtc_tm datetime ) {
    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x5;
    GPIO_PORT_DIRECTION = 0x7;

    rtc_write_command( CMD_DATETIME_WRITE );

    int bytes = 6;
    do {
        rtc_write_data8( ( int ) ( datetime >> ( bytes * 8 ) ) & 0xff );
    } while ( bytes-- > 0 );

    GPIO_PORT_DATA = 0x1;
    GPIO_PORT_DATA = 0x1;
}
