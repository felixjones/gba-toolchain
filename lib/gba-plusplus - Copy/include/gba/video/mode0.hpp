#ifndef GBAXX_VIDEO_MODE0_HPP
#define GBAXX_VIDEO_MODE0_HPP

#include <gba/io/memmap.hpp>
#include <gba/video/background_regular.hpp>
#include <gba/video/mode.hpp>

namespace gba {

/**
 *
 */
template <>
struct mode<0> {
    using background0_control = iomemmap<background_regular::control, 0x4000008>;
    using background1_control = iomemmap<background_regular::control, 0x400000a>;
    using background2_control = iomemmap<background_regular::control, 0x400000c>;
    using background3_control = iomemmap<background_regular::control, 0x400000e>;

    using background0_x = omemmap<int16, 0x4000010>;
    using background0_y = omemmap<int16, 0x4000012>;
    using background1_x = omemmap<int16, 0x4000014>;
    using background1_y = omemmap<int16, 0x4000016>;
    using background2_x = omemmap<int16, 0x4000018>;
    using background2_y = omemmap<int16, 0x400001a>;
    using background3_x = omemmap<int16, 0x400001c>;
    using background3_y = omemmap<int16, 0x400001e>;

    /**
     *
     */
    struct display_control : gba::display_control {
        constexpr display_control() noexcept : gba::display_control { 0, false, false, false, false, false, false,
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

        constexpr auto& layer_background_0( const bool value ) noexcept {
            gba::display_control::layer_background_0 = value;
            return *this;
        }

        constexpr auto& layer_background_1( const bool value ) noexcept {
            gba::display_control::layer_background_1 = value;
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
    };
};

} // gba

#endif // define GBAXX_VIDEO_MODE0_HPP
