#include <tonc.h>
#include <agbabi.h>
#include <gbfs.h>

[[gnu::section(".cart.backup"), gnu::used]]
constexpr const char save_type[] = "FLASH512_Vnnn";

void render();

int main() {
    REG_DISPCNT = DCNT_BG2 | DCNT_MODE3;
    render();
}
