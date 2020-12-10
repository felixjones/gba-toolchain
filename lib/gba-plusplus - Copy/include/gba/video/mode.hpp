#ifndef GBAXX_VIDEO_MODE_HPP
#define GBAXX_VIDEO_MODE_HPP

#include <gba/video/display_control.hpp>

namespace gba {

/**
 *
 * @tparam Graphics mode (0, 1, 2, 3, 4, 5)
 */
template <unsigned Mode>
struct mode {
    static_assert( Mode < 6, "Invalid display mode" );
};

} // gba

#endif // define GBAXX_VIDEO_MODE_HPP
