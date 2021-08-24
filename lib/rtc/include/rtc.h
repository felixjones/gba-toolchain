#ifndef LIBRTC_RTC_H
#define LIBRTC_RTC_H

#define RTC_EPOWER  ( 1 )
#define RTC_E12HOUR ( 2 )
#define RTC_EYEAR   ( 3 )
#define RTC_EMON    ( 4 )
#define RTC_EDAY    ( 5 )
#define RTC_EWDAY   ( 6 )
#define RTC_EHOUR   ( 7 )
#define RTC_EMIN    ( 8 )
#define RTC_ESEC    ( 9 )

#define RTC_TM_YEAR( X )    ( ( ( X ) >> 48 ) & 0xff )
#define RTC_TM_MON( X )     ( ( ( X ) >> 40 ) & 0xff )
#define RTC_TM_MDAY( X )    ( ( ( X ) >> 32 ) & 0xff )
#define RTC_TM_WDAY( X )    ( ( ( X ) >> 24 ) & 0xff )
#define RTC_TM_HOUR( X )    ( ( ( X ) >> 16 ) & 0xff )
#define RTC_TM_MIN( X )     ( ( ( X ) >> 8 ) & 0xff )
#define RTC_TM_SEC( X )     ( ( ( X ) >> 0 ) & 0xff )

typedef int rtc_time;
typedef long long int rtc_tm;

int __rtc_init();
int __rtc_get_status();
rtc_time __rtc_get_time();
rtc_tm __rtc_get_datetime();
void __rtc_set_time( rtc_time time );
void __rtc_set_datetime( rtc_tm datetime );

#endif // define LIBRTC_RTC_H
