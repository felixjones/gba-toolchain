#ifndef GBAXX_VIDEO_MODE5_HPP
#define GBAXX_VIDEO_MODE5_HPP

#include <gba/video/mode.hpp>

namespace gba {

/**
 *
 */
template <>
struct mode<5> {
    struct display_control : gba::display_control {
        constexpr display_control() noexcept : gba::display_control { 5, false, false, false, false, false, false,
                                                                      false, false, false, false, false, false,
                                                                      false } {}

        constexpr auto& page_select( const bool value ) noexcept {
            gba::display_control::page_select = value;
            return *this;
        }

        constexpr auto& object_horizontal_blank_access( const bool value ) noexcept {
            gba::display_control::object_horizontal_blank_access = value;
            return *this;
        }

        constexpr auto& object_mapping_linear( const bool value ) noexcept {
            gba::display_control::object_mapping_linear = value;
            return *this;
        }

        constexpr auto& force_blank( const bool value ) noexcept {
            gba::display_control::force_blank = value;
            return *this;
        }

        constexpr auto& layer_background_2( const bool value ) noexcept {
            gba::display_control::layer_background_2 = value;
            return *this;
        }

        constexpr auto& layer_object( const bool value ) noexcept {
            gba::display_control::layer_object = value;
            return *this;
        }

        constexpr auto& window_0( const bool value ) noexcept {
            gba::display_control::window_0 = value;
            return *this;
        }

        constexpr auto& window_1( const bool value ) noexcept {
            gba::display_control::window_1 = value;
            return *this;
        }

        constexpr auto& window_object( const bool value ) noexcept {
            gba::display_control::window_object = value;
            return *this;
        }

    protected:
        using gba::display_control::mode;
        using gba::display_control::game_boy;
        using gba::display_control::layer_background_0;
        using gba::display_control::layer_background_1;
        using gba::display_control::layer_background_3;
    };
};

} // gba

#endif // define GBAXX_VIDEO_MODE5_HPP
