#ifndef GBAXX_VIDEO_BACKGROUND_CONTROL_HPP
#define GBAXX_VIDEO_BACKGROUND_CONTROL_HPP

#include <gba/types/int_type.hpp>

namespace gba {

enum class background_color : uint16 {
    bpp4 = 0,
    bpp8 = 1
};

enum class background_size : uint16 {
    regular_32x32 = 0,
    regular_64x32 = 1,
    regular_32x64 = 2,
    regular_64x64 = 3,

    affine_16x16 = 0,
    affine_32x32 = 1,
    affine_64x64 = 2,
    affine_128x128 = 3
};

/**
 *
 */
struct background_control {
    uint16 priority : 2,
            character_block : 2, : 2;
    bool mosaic : 1;
    background_color color_mode : 1;
    uint16 screen_block : 5;
    bool affine_wrap : 1;
    background_size size : 2;
};

static_assert( sizeof( background_control ) == 2, "background_control must be tightly packed" );

} // gba

#endif // define GBAXX_VIDEO_BACKGROUND_CONTROL_HPP
