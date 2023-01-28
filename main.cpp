#include <tonc.h>

#include <aeabi.h>
#include <agbabi.h>

[[gnu::section(".cart.backup"), gnu::used]]
constexpr const char save_type[] = "FLASH512_Vnnn";

void render();

alignas(int) unsigned char u8_array[] = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'};

int main() {
    __aeabi_memclr(u8_array + 3, 7);

    int stack[40];
    __agbabi_coro_t coro;

    __agbabi_coro_make(&coro, stack + 40, [](auto* self) {
        int count = 10;
        while (--count) {
            __agbabi_coro_yield(self, count);
        }
        return 0;
    });

    int val;
    do {
        val = __agbabi_coro_resume(&coro);
    } while (val);

    REG_DISPCNT = DCNT_BG2 | DCNT_MODE3;
    render();
}
