#include <tonc.h>

#include <gba_eeprom.h>
#include <gba_flash.h>
#include <gba_sram.h>

struct FlashInfo {
    u8 device;
    u8 manufacturer;
    u8 size;
};

extern struct FlashInfo gFlashInfo;

int main(void) {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

	tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));

    tte_init_con();

    // Test SRAM
    int err = sram_write(0, "S", 1);
    if (!err) {
        tte_printf("Save Type: SRAM\n");
        sram_write(0x8000, "R", 1);
        u8 a = '\0';
        sram_read(0, &a, 1);
        switch (a) {
            case 'R':
                tte_printf("Size: 32KB\n");
                break;
            case 'S':
                tte_printf("Size: 64KB\n");
                break;
            default:
                tte_printf("Size: ?\n");
                break;
        }
        goto end;
    }

    // Test EEPROM
    eeprom_init(EEPROM_SIZE_8KB);
    u16 data[5] = {1, 2, 3, 4, 5};
    err = eeprom_write(0, data);
    if (!err) {
        eeprom_read(0, &data[1]);
        if (data[1] == 1) {
            tte_printf("Save Type: EEPROM\nSize: 8KB\n");
            goto end;
        }
    }
    eeprom_init(EEPROM_SIZE_512B);
    data[0] = 1;
    data[1] = 2;
    err = eeprom_write(0, data);
    if (!err) {
        eeprom_read(0, &data[1]);
        if (data[1] == 1) {
            tte_printf("Save Type: EEPROM\nSize: 512B\n");
            goto end;
        }
    }

    // Test Flash
    err = flash_init(FLASH_SIZE_AUTO);
    if (err) {
        tte_printf("Unknown save type\n");
        goto end;
    }

    tte_printf("Save Type: Flash\n");
    tte_printf("Manufacturer ID: %X\nDevice ID: %X\n", gFlashInfo.manufacturer, gFlashInfo.device);
    switch (gFlashInfo.size) {
        case FLASH_SIZE_64KB:
            tte_printf("Size: 64KB\n");
            break;
        case FLASH_SIZE_128KB:
            tte_printf("Size: 128KB\n");
            break;
        default:
            tte_printf("Size: ?\n");
            break;
    }

end:
	irq_init(NULL);
	irq_enable(II_VBLANK);

	while (1) {
		VBlankIntrWait();
	}
}
