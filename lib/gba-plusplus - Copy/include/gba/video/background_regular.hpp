#ifndef GBAXX_VIDEO_BACKGROUND_REGULAR_HPP
#define GBAXX_VIDEO_BACKGROUND_REGULAR_HPP

#include <gba/video/background_control.hpp>

namespace gba {

struct background_regular {

    /**
     *
     */
    struct control : gba::background_control {
        constexpr control() noexcept : gba::background_control { 0, 0, false, background_color::bpp4, 0, false, background_size::regular_32x32 } {}

        constexpr auto& priority( const int value ) noexcept {
            gba::background_control::priority = value;
            return *this;
        }

        constexpr auto& character_block( const int value ) noexcept {
            gba::background_control::character_block = value;
            return *this;
        }

        constexpr auto& mosaic( const bool value ) noexcept {
            gba::background_control::mosaic = value;
            return *this;
        }

        constexpr auto& color_mode( const background_color value ) noexcept {
            gba::background_control::color_mode = value;
            return *this;
        }

        constexpr auto& screen_block( const int value ) noexcept {
            gba::background_control::screen_block = value;
            return *this;
        }

        constexpr auto& size( const background_size value ) noexcept {
            gba::background_control::size = value;
            return *this;
        }

    protected:
        using gba::background_control::affine_wrap;
    };

};

} // gba

#endif // define GBAXX_VIDEO_BACKGROUND_REGULAR_HPP
