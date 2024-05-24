/*
===============================================================================

 https://github.com/GValiente/butano/tree/master/examples/dmg_audio

 Copyright (c) 2020-2024 Gustavo Valiente gustavo.valiente@protonmail.com
 Copyright (C) 2024 gba-toolchain contributors

 zlib License

 (C) 2020-2024 Gustavo Valiente (gustavo.valiente@prontonmail.com)

 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.

 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:

 1. The origin of this software must not be misrepresented; you must not
    claim that you wrote the original software. If you use this software
    in a product, an acknowledgment in the product documentation would be
    appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
    misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.

===============================================================================
*/

#include "bn_audio.h"
#include "bn_bg_palettes.h"
#include "bn_core.h"
#include "bn_dmg_music_actions.h"
#include "bn_keypad.h"
#include "bn_sprite_text_generator.h"

#include "common_info.h"
#include "common_variable_8x16_sprite_font.h"

#include "bn_dmg_music_items_arachno_a_sad_touch.h"
#include "bn_dmg_music_items_s3m_template.h"

namespace {
    void dmg_music_scene(bn::sprite_text_generator& text_generator) {
        static constexpr bn::string_view info_text_lines[] = {
            "LEFT: decrease volume",
            "RIGHT: increase volume",
            "A: pause/resume music",
            "",
            "",
            "",
            "",
            "START: go to next scene",
        };

        common::info info("DMG music", info_text_lines, text_generator);
        info.set_show_always(true);

        bn::dmg_music_items::s3m_template.play();

        while (!bn::keypad::start_pressed()) {
            const bn::fixed volume = bn::dmg_music::left_volume();

            if (bn::keypad::left_held()) {
                bn::dmg_music::set_volume(bn::max(volume - 0.01, bn::fixed(0)));
            } else if (bn::keypad::right_held()) {
                bn::dmg_music::set_volume(bn::min(volume + 0.01, bn::fixed(1)));
            }

            if (bn::keypad::a_pressed()) {
                if (bn::dmg_music::paused()) {
                    bn::dmg_music::resume();
                } else {
                    bn::dmg_music::pause();
                }
            }

            info.update();
            bn::core::update();
        }

        bn::dmg_music::stop();
    }

    void dmg_music_actions_scene(bn::sprite_text_generator& text_generator) {
        static constexpr bn::string_view info_text_lines[] = {
            "START: go to next scene",
        };

        common::info info("DMG music actions", info_text_lines, text_generator);
        info.set_show_always(true);

        bn::dmg_music_items::s3m_template.play();
        bn::dmg_music::set_volume(0);

        bn::dmg_music_volume_loop_action action(120, 1);

        while (!bn::keypad::start_pressed()) {
            action.update();
            info.update();
            bn::core::update();
        }

        bn::dmg_music::stop();
    }

    void vgm_music_scene(bn::sprite_text_generator& text_generator) {
        static constexpr bn::string_view info_text_lines[] = {
            "A: stop/play music",
            "",
            "",
            "",
            "",
            "",
            "",
            "START: go to next scene",
        };

        common::info info("VGM music", info_text_lines, text_generator);
        info.set_show_always(true);

        bn::dmg_music_items::arachno_a_sad_touch.play();

        while (!bn::keypad::start_pressed()) {
            if (bn::keypad::a_pressed()) {
                if (bn::dmg_music::playing()) {
                    bn::dmg_music::stop();
                } else {
                    bn::dmg_music_items::arachno_a_sad_touch.play();
                }
            }

            info.update();
            bn::core::update();
        }

        bn::dmg_music::stop();
    }

    void dmg_music_master_volume_scene(bn::sprite_text_generator& text_generator) {
        static constexpr bn::string_view info_text_lines[] = {
            "LEFT: decrease volume",
            "RIGHT: increase volume",
            "",
            "",
            "",
            "",
            "",
            "START: go to next scene",
        };

        common::info info("DMG music master volume", info_text_lines, text_generator);
        info.set_show_always(true);

        bn::dmg_music_items::arachno_a_sad_touch.play();

        while (!bn::keypad::start_pressed()) {
            bn::dmg_music_master_volume master_volume = bn::dmg_music::master_volume();

            if (bn::keypad::left_pressed()) {
                switch (master_volume) {
                    case bn::dmg_music_master_volume::QUARTER:
                        break;
                    case bn::dmg_music_master_volume::HALF:
                        master_volume = bn::dmg_music_master_volume::QUARTER;
                        break;
                    case bn::dmg_music_master_volume::FULL:
                        master_volume = bn::dmg_music_master_volume::HALF;
                        break;
                    default:
                        break;
                }
            } else if (bn::keypad::right_pressed()) {
                switch (master_volume) {
                    case bn::dmg_music_master_volume::QUARTER:
                        master_volume = bn::dmg_music_master_volume::HALF;
                        break;
                    case bn::dmg_music_master_volume::HALF:
                        master_volume = bn::dmg_music_master_volume::FULL;
                        break;
                    case bn::dmg_music_master_volume::FULL:
                    default:
                        break;
                }
            }

            bn::dmg_music::set_master_volume(master_volume);

            info.update();
            bn::core::update();
        }

        bn::dmg_music::stop();
        bn::dmg_music::set_master_volume(bn::dmg_music_master_volume::QUARTER);
    }
}

[[noreturn]]
int main() {
    bn::core::init();

    bn::sprite_text_generator text_generator(common::variable_8x16_sprite_font);
    bn::bg_palettes::set_transparent_color(bn::color(16, 16, 16));

    while (true) {
        dmg_music_scene(text_generator);
        bn::core::update();

        dmg_music_actions_scene(text_generator);
        bn::core::update();

        vgm_music_scene(text_generator);
        bn::core::update();

        dmg_music_master_volume_scene(text_generator);
        bn::core::update();
    }
}
