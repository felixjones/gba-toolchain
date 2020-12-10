#ifndef GBAXX_BIOS_HALT_HPP
#define GBAXX_BIOS_HALT_HPP

#include <gba/bios/swi.hpp>
#include <gba/interrupt/flags.hpp>
#include <gba/io/bit_container.hpp>

namespace gba {
namespace bios {

[[gnu::always_inline]]
inline void halt() noexcept {
    swi<2, void()>::call();
}

[[gnu::always_inline]]
inline void stop() noexcept {
    swi<3, void()>::call();
}

[[gnu::always_inline]]
inline void intr_wait( bool resetFlag, irq::flags flags ) noexcept {
    swi<4, void( int, int )>::call( resetFlag, to_bit_container( flags ) );
}

[[gnu::always_inline]]
inline void vblank_intr_wait() noexcept {
    swi<5, void( void )>::clobber_call_0_1();
}

namespace undocumented {

[[gnu::always_inline]]
inline void custom_halt( bool stop ) noexcept {
    swi<0x27, void( int )>::call_r2( stop ? 0x80 : 0 );
}

} // undocumented
} // bios
} // gba

#endif // define GBAXX_BIOS_HALT_HPP
