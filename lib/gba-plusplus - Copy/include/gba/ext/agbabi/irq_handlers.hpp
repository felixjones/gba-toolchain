#ifndef GBAXX_EXT_AGBABI_INTERRUPT_HANDLERS_HPP
#define GBAXX_EXT_AGBABI_INTERRUPT_HANDLERS_HPP

#include <functional>

#include <gba/interrupt/flags.hpp>
#include <gba/io/memmap.hpp>

#if defined( __agb_abi )

extern void ( * __agbabi_irq_empty )( void );
extern void ( * __agbabi_irq_user )( void );
extern void ( * __agbabi_irq_uproc )( gba::irq::flags );

#endif

namespace gba {
namespace agbabi {

struct interrupt_handler : omemmap<void ( ** )( void ), 0x3007FFC> {
    static void set( [[maybe_unused]] std::nullptr_t ) noexcept {
        omemmap::write( &__agbabi_irq_empty );
    }

    static void set( void ( * uproc )( irq::flags ) ) noexcept {
        __agbabi_irq_uproc = uproc;
        omemmap::write( &__agbabi_irq_user );
    }
};

[[gnu::constructor]]
inline void initialize() noexcept {
    interrupt_handler::set( nullptr );
}

} // agbabi
} // gba

#endif // define GBAXX_EXT_AGBABI_INTERRUPT_HANDLERS_HPP
