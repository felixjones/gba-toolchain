#ifndef GBAXX_VIDEO_DISPLAY_CONTROL_HPP
#define GBAXX_VIDEO_DISPLAY_CONTROL_HPP

#include <gba/types/int_type.hpp>

namespace gba {

/**
 *
 */
struct display_control {
    uint16 mode : 3;
    bool game_boy : 1,
            page_select : 1,
            object_horizontal_blank_access : 1,
            object_mapping_linear : 1,
            force_blank : 1,
            layer_background_0 : 1,
            layer_background_1 : 1,
            layer_background_2 : 1,
            layer_background_3 : 1,
            layer_object : 1,
            window_0 : 1,
            window_1 : 1,
            window_object : 1;
};

static_assert( sizeof( display_control ) == 2, "display_control must be tightly packed" );

} // gba

#endif // define GBAXX_VIDEO_DISPLAY_CONTROL_HPP
