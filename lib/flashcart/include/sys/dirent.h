#ifndef GBA_SYS_DIRENT_H_
#define	GBA_SYS_DIRENT_H_

typedef void * DIR;

typedef struct dirent {
    unsigned long long	fsize;
    unsigned short	    fdate;
    unsigned short	    ftime;
    unsigned char	    fattrib;
    char	            altname[13];
    char	            d_name[256];
} dirent;

#define	AM_RDO  ( 0x01 )
#define	AM_HID  ( 0x02 )
#define	AM_SYS  ( 0x04 )
#define AM_DIR  ( 0x10 )
#define AM_ARC  ( 0x20 )

#endif // define GBA_SYS_DIRENT_H_
