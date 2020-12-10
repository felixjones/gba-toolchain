#ifndef GBAXX_VIDEO_DISPLAY_STATUS_HPP
#define GBAXX_VIDEO_DISPLAY_STATUS_HPP

#include <gba/types/int_type.hpp>

namespace gba {

/**
 *
 */
struct display_status {
    const bool in_vertical_blank : 1,
            in_horizontal_blank : 1,
            in_vertical_count : 1;
    bool vertical_blank_irq : 1,
            horizontal_blank_irq : 1,
            vertical_count_irq : 1;
    uint8 vertical_count_trigger;
};

struct display_status_irq : display_status {
    constexpr display_status_irq() noexcept : display_status { false, false, false, false, false, false, 0 } {}

    constexpr auto& vertical_blank( bool e ) noexcept {
        display_status::vertical_blank_irq = e;
        return *this;
    }

    constexpr auto& horizontal_blank( bool e ) noexcept {
        display_status::horizontal_blank_irq = e;
        return *this;
    }

    constexpr auto& vertical_count( bool e ) noexcept {
        display_status::vertical_count_irq = e;
        return *this;
    }

    constexpr auto& vertical_count_trigger( int line ) noexcept {
        display_status::vertical_count_trigger = line;
        return *this;
    }

protected:
    using display_status::in_vertical_blank;
    using display_status::in_horizontal_blank;
    using display_status::in_vertical_count;
};

static_assert( sizeof( display_status ) == 2, "display_status must be tightly packed" );

} // gba

#endif // define GBAXX_VIDEO_DISPLAY_STATUS_HPP
