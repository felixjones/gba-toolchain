#include <sys/time.h>
#include <errno.h>
#include <time.h>
#include <rtc.h>

#undef errno
extern int errno;

#define bcd_decode( x ) ( ( ( x ) & 0xfu ) + ( ( ( x ) >> 4u ) * 10u ) )

#define REG_IME ( *( volatile unsigned short * ) 0x04000208 )

int _gettimeofday( struct timeval * tv, void * tz ) {
    extern int _dsk_rtc;

    if ( _dsk_rtc ) {
        errno = EPERM;
        return -1;
    }

    const int ime = REG_IME;
    REG_IME = 0;
    const rtc_tm datetime = __rtc_get_datetime();
    REG_IME = ime;

    struct tm time;
    time.tm_year = bcd_decode( RTC_TM_YEAR( datetime ) ) + ( 2000u - 1900u );
    time.tm_mon = bcd_decode( RTC_TM_MON( datetime ) ) - 1;
    time.tm_mday = bcd_decode( RTC_TM_MDAY( datetime ) );

    time.tm_hour = bcd_decode( RTC_TM_HOUR( datetime ) );
    time.tm_min = bcd_decode( RTC_TM_MIN( datetime ) );
    time.tm_sec = bcd_decode( RTC_TM_SEC( datetime ) );

    time.tm_wday = bcd_decode( RTC_TM_WDAY( datetime ) );
    time.tm_yday = 0;
    time.tm_isdst = 0;

    tv->tv_usec = 0;
    tv->tv_sec = mktime( &time );
    return 0;
}
