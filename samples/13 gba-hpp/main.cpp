/*
===============================================================================

 gba-hpp demo

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <gba/gba.hpp>

static constexpr auto red = gba::uint16{0x1f};
static constexpr auto green = gba::uint16{0x1f << 5 | 1 << 15};
static constexpr auto blue = gba::uint16{0x1f << 10};

static constexpr auto reset_keys = gba::key::a | gba::key::b | gba::key::select | gba::key::start;

int main() {
    using namespace gba;

    irq::handler::set(nullptr); // Initialize empty IRQ handler
    reg::ie::set(irq::vblank);
    reg::dispstat::set(dispstat::vbl_irq);

    reg::dispcnt::set(dispcnt::mode(3) | dispcnt::bg2);

    mode<3>::put(120, 80, red);
    mode<3>::put(136, 80, blue);
    mode<3>::put(120, 96, green);

    reg::ime::set(true);

    key_state keys;
    while (!keys.poll().down(reset_keys)) {
        bios::VBlankIntrWait();
    }

    reg::ime::set(false);
    reg::dispcnt::set(dispcnt::blank);
    while (keys.poll().down(reset_keys)) {}
}
