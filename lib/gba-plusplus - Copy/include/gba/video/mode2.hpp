#ifndef GBAXX_VIDEO_MODE2_HPP
#define GBAXX_VIDEO_MODE2_HPP

#include <gba/io/memmap.hpp>
#include <gba/video/background_affine.hpp>
#include <gba/video/mode.hpp>

namespace gba {

/**
 *
 */
template <>
struct mode<2> {
    using background2_control = iomemmap<background_affine::control, 0x400000c>;
    using background3_control = iomemmap<background_affine::control, 0x400000e>;

    /**
     *
     */
    struct display_control : gba::display_control {
        constexpr display_control() noexcept : gba::display_control { 2, false, false, false, false, false, false,
                                                                      false, false, false, false, false, false,
                                                                      false } {}

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

        constexpr auto& layer_background_3( const bool value ) noexcept {
            gba::display_control::layer_background_3 = value;
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
        using gba::display_control::page_select;
        using gba::display_control::layer_background_0;
        using gba::display_control::layer_background_1;
    };
};


} // gba

#endif // define GBAXX_VIDEO_MODE2_HPP
