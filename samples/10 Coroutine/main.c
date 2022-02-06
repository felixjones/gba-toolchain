/*
===============================================================================

 Coroutines demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <agbabi.h>
#include <tonc.h>
#include <posprintf.h>

// Returns first 10 fibonacci numbers
static int fibonacci(agbabi_coro_t* coro);

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(48, 68);

    irq_init(NULL);
    irq_enable(II_VBLANK);

    // Create coroutine with 80 bytes of stack
    char stack[80];
    agbabi_coro_t coro;
    __agbabi_coro_make(&coro, stack + sizeof(stack), fibonacci);

    while (coro.alive) {
        int value = __agbabi_coro_resume(&coro);

        char buffer[80];
        posprintf(buffer, "%d ", value);
        tte_write(buffer);
    }

    while (1) {
        VBlankIntrWait();
    }
    __builtin_unreachable();
}

static int fibonacci(agbabi_coro_t* coro) {
    int first = 1, second = 1;
    __agbabi_coro_yield(coro, first);
    __agbabi_coro_yield(coro, second);

    for (int i = 0; i < 7; ++i) {
        int third = first + second;
        first = second;
        second = third;
        __agbabi_coro_yield(coro, third);
    }

    return first + second;
}
