#ifndef GBAXX_BIOS_SWI_HPP
#define GBAXX_BIOS_SWI_HPP

namespace gba {
namespace bios {

template <unsigned Swi, class Function>
struct swi;

template <unsigned Swi>
struct swi<Swi, void( void )> {
    [[gnu::always_inline]]
    static void call() noexcept {
        asm inline (
#if defined( __thumb__ )
        "swi\t%[Swi]"
#elif defined( __arm__ )
        "swi\t%[Swi] << 16"
#endif
        :: [Swi]"i"( Swi )
        );
    }

    [[gnu::always_inline]]
    static void clobber_call_0_1() noexcept {
        asm inline (
#if defined( __thumb__ )
        "swi\t%[Swi]"
#elif defined( __arm__ )
        "swi\t%[Swi] << 16"
#endif
        :: [Swi]"i"( Swi ) : "r0", "r1"
        );
    }
};

template <unsigned Swi>
struct swi<Swi, void( int )> {
    [[gnu::always_inline]]
    static void call_r2( int&& arg0 ) noexcept {
        asm inline (
        #if defined( __thumb__ )
        "movs\tr2, %[arg0]\n\t"
        "swi\t%[Swi]"
#elif defined( __arm__ )
        "mov\tr2, %[arg0]\n\t"
        "swi\t%[Swi] << 16"
#endif
        :: [Swi]"i"( Swi ), [arg0]"ri"( arg0 ) : "r2"
        );
    }
};

template <unsigned Swi>
struct swi<Swi, void( int, int )> {
    [[gnu::always_inline]]
    static void call( int&& arg0, int&& arg1 ) noexcept {
        asm inline (
        #if defined( __thumb__ )
        "movs\tr0, %[arg0]\n\t"
        "movs\tr1, %[arg1]\n\t"
        "swi\t%[Swi]"
#elif defined( __arm__ )
        "mov\tr0, %[arg0]\n\t"
        "mov\tr1, %[arg1]\n\t"
        "swi\t%[Swi] << 16"
#endif
        :: [Swi]"i"( Swi ), [arg0]"ri"( arg0 ), [arg1]"ri"( arg1 ) : "r0", "r1"
        );
    }
};
template <unsigned Swi>
struct swi<Swi, unsigned int( unsigned int )> {
    [[nodiscard, gnu::always_inline, gnu::pure]]
    static unsigned int call( unsigned int && arg0 ) noexcept {
        asm inline (
#if defined( __thumb__ )
        "movs\tr0, %[arg0]\n\t"
        "swi\t%[Swi]\n\t"
        "movs\t%[arg0], r0"
#elif defined( __arm__ )
        "mov\tr0, %[arg0]\n\t"
        "swi\t%[Swi] << 16\n\t"
        "mov\t%[ret], r0"
#endif
        : [arg0]"+ri"( arg0 ) : [Swi]"i"( Swi ) :"r0"
        );
        return arg0;
    }
};

} // bios
} // gba

#endif // define GBAXX_BIOS_SWI_HPP
