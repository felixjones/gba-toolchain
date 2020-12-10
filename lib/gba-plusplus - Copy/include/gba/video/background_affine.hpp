#ifndef GBAXX_VIDEO_BACKGROUND_AFFINE_HPP
#define GBAXX_VIDEO_BACKGROUND_AFFINE_HPP

#include <gba/video/background_control.hpp>

namespace gba {

struct background_affine {

    /**
     *
     */
    struct control : gba::background_control {
        constexpr control() noexcept : gba::background_control { 0, 0, false, background_color::bpp8, 0, false, background_size::regular_32x32 } {}

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

        constexpr auto& screen_block( const int value ) noexcept {
            gba::background_control::screen_block = value;
            return *this;
        }

        constexpr auto& affine_wrap( const bool value ) noexcept {
            gba::background_control::affine_wrap = value;
            return *this;
        }

        constexpr auto& size( const background_size value ) noexcept {
            gba::background_control::size = value;
            return *this;
        }

    protected:
        using gba::background_control::color_mode;
    };

};

} // gba

#endif // define GBAXX_VIDEO_BACKGROUND_AFFINE_HPP
