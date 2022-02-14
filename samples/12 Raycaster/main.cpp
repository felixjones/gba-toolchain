/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include <cstdint>

#include <seven/prelude.h>
#include <seven/video/bg_bitmap.h>
#include <seven/util/log.h>

#include "asset_manager.hpp"
#include "renderer.hpp"

static constinit const auto reset_key_combo = std::uint16_t(KEY_A | KEY_B | KEY_SELECT | KEY_START);

int main() {
    logInit();
    logSetMaxLevel(LOG_TRACE);

    assets::load();
    renderer::init();

    // TODO : Setup VBlanking
//    irqInitStub();
//    REG_DISPSTAT = LCD_STATUS_VBLANK_IRQ_ENABLE;
//    REG_IE = IRQ_VBLANK;
//    REG_IME = 1;

    // Mode 4 background
    lcdInitMode4();

    void* frameBuffer = MODE4_FRAME;
    auto camera = camera_type { 22.0, 11.5, 0x4001 };

    while (!inputKeysDown(reset_key_combo)) {
        renderer::draw_world(reinterpret_cast<std::uint8_t*>(frameBuffer), camera);

        frameBuffer = lcdSwapBuffers();

        inputPoll();
        camera.update();
    }

    // Spin loop while reset keys are held
    REG_IME = 0;
    REG_DISPCNT = 0;
    while (inputKeysDown(reset_key_combo)) {
        inputPoll();
    }

    return 0;
}
