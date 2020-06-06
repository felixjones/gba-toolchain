#ifndef TOOLBOX_HPP
#define TOOLBOX_HPP

#include <array>
#include <cstdint>
#include <cstring>

// GBA hardware addresses
namespace mem {
    constexpr auto io = 0x04000000;
    constexpr auto vram = 0x06000000;
}

// 15bpp pixel color type
struct rgb15 {
    template <unsigned Red, unsigned Green, unsigned Blue>
    static constexpr auto make() noexcept {
        return rgb15 { Red, Green, Blue };
    }

    std::uint16_t   red : 5,
                    green : 5,
                    blue : 5,
                    : 1; // spare bit
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

    std::uint16_t   data;
};

// Register access
namespace reg {
    static void dispcnt_set( const display_control& other ) noexcept {
        std::uint16_t data;
        std::memcpy( &data, &other, sizeof( data ) ); // bit_cast
        *reinterpret_cast<volatile std::uint16_t *>( mem::io ) = data;
    }
}

// Mode graphics
template <unsigned Mode>
struct mode {};

// Mode 3 graphics
template <>
struct mode<3> {
    static void plot( int x, int y, rgb15 color ) noexcept {
        reinterpret_cast<rgb15 *>( mem::vram )[y * 240 + x] = color;
    }
};

#endif // define TOOLBOX_HPP
