#ifndef GBAXX_BIOS_SQRT_HPP
#define GBAXX_BIOS_SQRT_HPP

#include <gba/bios/swi.hpp>

namespace gba {
namespace bios {

[[nodiscard, gnu::always_inline, gnu::pure]]
inline unsigned int sqrt( unsigned int && x ) noexcept {
    return swi<8, unsigned int(unsigned int)>::call( std::move( x ) );
}

} // bios
} // gba

#endif // define GBAXX_BIOS_SQRT_HPP
