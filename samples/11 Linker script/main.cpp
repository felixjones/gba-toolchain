/*
===============================================================================

 Very basic C++ program that prints an exception to the screen

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <tonc.h>

#include <stdexcept>

static void throw_exception();

int main() {
    REG_DISPCNT = DCNT_MODE0 | DCNT_BG0;

    tte_init_chr4c_default(0, BG_CBB(0) | BG_SBB(31));
    tte_set_pos(48, 68);

    try {
        throw_exception();
    } catch (std::runtime_error& e) {
        tte_write(e.what());
    }

    irq_init(nullptr);
    irq_enable(II_VBLANK);

    while (1) {
        VBlankIntrWait();
    }
    __builtin_unreachable();
}

static void throw_exception() {
    throw std::runtime_error("Exception thrown!");
}
