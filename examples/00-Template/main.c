#include <tonc.h>

#include <map.h>
#include <sprite.h>

static void load_map();

static void load_sprite();

int main() {
    irq_init(NULL);
    irq_enable(II_VBLANK);

    load_map();
    load_sprite();

    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0 | DCNT_OBJ | DCNT_OBJ_1D;

    int x = 192, y = 64;
    while (1) {
        key_poll();

        x += key_tri_horz();
        y += key_tri_vert();

        VBlankIntrWait();

        REG_BG0HOFS = x;
        REG_BG0VOFS = y;
    }
}

static void load_map() {
    dma3_cpy(pal_bg_mem, brinPal, brinPalLen);
    dma3_cpy(&tile_mem[0][0], brinTiles, brinTilesLen);
    dma3_cpy(&se_mem[30][0], brinMap, brinMapLen);

    REG_BG0CNT = BG_CBB(0) | BG_SBB(30) | BG_4BPP | BG_REG_64x32;
}

static void load_sprite() {
    static OBJ_ATTR obj_buffer[128];

    dma3_cpy(&tile_mem[4][0], metrTiles, metrTilesLen);
    dma3_cpy(pal_obj_mem, metrPal, metrPalLen);

    oam_init(obj_buffer, 128);

    obj_set_attr(&obj_buffer[0], ATTR0_SQUARE, ATTR1_SIZE_64, ATTR2_PALBANK(0));

    obj_set_pos(&obj_buffer[0], 88, 48);

    oam_copy(oam_mem, obj_buffer, 1);
}
