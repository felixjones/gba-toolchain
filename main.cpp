#include <tonc.h>

void render();

int main() {
    REG_DISPCNT = DCNT_BG2 | DCNT_MODE3;
    render();
}
