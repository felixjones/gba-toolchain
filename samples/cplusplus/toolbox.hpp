#ifndef TOOLBOX_HPP
#define TOOLBOX_HPP

#include <cstdint>

#if !defined( __has_builtin )
#define __has_builtin( x )  0
#endif

#if __cpp_lib_bit_cast
#include <bit>
#elif !__has_builtin( __builtin_bit_cast )
#include <cstring>
#endif

// GBA hardware addresses
namespace mem {
    constexpr auto io = 0x04000000;
    constexpr auto vram = 0x06000000;
}

// 15bpp pixel color type
struct rgb15 {
    template <unsigned Red, unsigned Green, unsigned Blue>
    static constexpr auto make() noexcept {
        return rgb15{ Red, Green, Blue };
    }

    std::uint16_t red : 5, green : 5, blue : 5, : 1; // spare bit
};

// Display control type
struct display_control {
    constexpr display_control() noexcept : data( 0 ) {}

    constexpr auto& mode( int mode ) noexcept {
        data |= mode & 0x7;
        return *this;
    }

    constexpr auto& background( int background ) noexcept {
        data |= ( background & 0xf ) << 9;
        return *this;
    }

    std::uint16_t data;
};

// Register access
namespace reg {
    namespace {
        void dispcnt_set( const display_control& displayControl ) noexcept {
            *reinterpret_cast<volatile std::uint16_t *>( mem::io ) = displayControl.data;
        }
    }
}

// Mode graphics
template <unsigned Mode>
struct mode {
};

// Mode 3 graphics
template <>
struct mode<3> {
    static void plot( int x, int y, rgb15 color ) noexcept {
#if __cpp_lib_bit_cast
        reinterpret_cast<volatile std::uint16_t *>( mem::vram )[y * 240 + x] = std::bit_cast<std::uint16_t>( color );
#elif __has_builtin( __builtin_bit_cast )
        reinterpret_cast<volatile std::uint16_t *>( mem::vram )[y * 240 + x] = __builtin_bit_cast( std::uint16_t, color );
#else
        std::uint16_t data;
        std::memcpy( &data, &color, sizeof( data ) );
        reinterpret_cast<volatile std::uint16_t *>( mem::vram )[y * 240 + x] = data;
#endif
    }
};

#endif // define TOOLBOX_HPP
