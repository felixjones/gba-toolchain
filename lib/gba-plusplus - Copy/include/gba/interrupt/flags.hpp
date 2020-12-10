#ifndef GBAXX_INTERRUPT_FLAGS_HPP
#define GBAXX_INTERRUPT_FLAGS_HPP

namespace gba {
namespace irq {

struct flags {
    bool vertical_blank : 1,
            horizontal_blank : 1,
            vertical_count : 1,
            timer_0 : 1,
            timer_1 : 1,
            timer_2 : 1,
            timer_3 : 1,
            serial_communication : 1,
            direct_memory_access : 1,
            keypad : 1,
            gamepak : 1;
};

struct enable : flags {
    constexpr enable() noexcept : flags { false, false, false, false, false, false, false, false, false, false,
                                          false } {}

    constexpr auto& vertical_blank( bool e ) noexcept {
        flags::vertical_blank = e;
        return *this;
    }

    constexpr auto& horizontal_blank( bool e ) noexcept {
        flags::horizontal_blank = e;
        return *this;
    }

    constexpr auto& vertical_count( bool e ) noexcept {
        flags::vertical_count = e;
        return *this;
    }

    constexpr auto& timer_0( bool e ) noexcept {
        flags::timer_0 = e;
        return *this;
    }

    constexpr auto& timer_1( bool e ) noexcept {
        flags::timer_1 = e;
        return *this;
    }

    constexpr auto& timer_2( bool e ) noexcept {
        flags::timer_2 = e;
        return *this;
    }

    constexpr auto& timer_3( bool e ) noexcept {
        flags::timer_3 = e;
        return *this;
    }

    constexpr auto& serial_communication( bool e ) noexcept {
        flags::serial_communication = e;
        return *this;
    }

    constexpr auto& direct_memory_access( bool e ) noexcept {
        flags::direct_memory_access = e;
        return *this;
    }

    constexpr auto& keypad( bool e ) noexcept {
        flags::keypad = e;
        return *this;
    }
};

static_assert( sizeof( flags ) == 2, "flags must be tightly packed" );

} // irq
} // gba

#endif // define GBAXX_INTERRUPT_FLAGS_HPP
