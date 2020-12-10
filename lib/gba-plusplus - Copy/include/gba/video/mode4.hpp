#ifndef GBAXX_VIDEO_MODE4_HPP
#define GBAXX_VIDEO_MODE4_HPP

#include <gba/io/bit_container.hpp>
#include <gba/video/mode.hpp>

namespace gba {

/**
 *
 */
template <>
struct mode<4> {

    /**
     *
     * @tparam Address starting address of frame buffer page
     */
    template <unsigned Address>
    struct frame_buffer {
        static constexpr auto address = Address;

        using pixel_type = uint8;
        struct pixel_pair {
            pixel_type data[2];
        };
        using buffer_row = uint16[120];

        static void put_pixel( int x, int y, pixel_type index ) noexcept {
            auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y][x / 2] );
            pair.data[x % 2] = index;
            reinterpret_cast<buffer_row *>( address )[y][x / 2] = to_bit_container( pair );
        }

        [[nodiscard]]
        static pixel_type get_pixel( int x, int y ) noexcept {
            auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y][x / 2] );
            return pair.data[x % 2];
        }

        static void clear_to_color( pixel_type index ) noexcept {
            std::fill( reinterpret_cast<pixel_pair *>( address ), reinterpret_cast<pixel_pair *>( address ) + ( 240 * 80 ), pixel_pair { index, index } );
        }

        static void rect_fill( int x1, int y1, int x2, int y2, pixel_type index ) noexcept {
            const auto fillPair = to_bit_container( pixel_pair { index, index } );
            const auto left = x1 + ( x1 % 2 );
            const auto right = x2 - ( x2 % 2 );

            const auto x12 = x1 / 2;
            const auto x22 = x2 / 2;
            const auto left2 = left / 2;
            const auto right2 = right / 2;

            for ( int yy = y1; yy < y2; ++yy ) {
                if ( x1 != left ) {
                    auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[yy][x12] );
                    pair.data[1] = index;
                    reinterpret_cast<buffer_row *>( address )[yy][x12] = to_bit_container( pair );
                }

                if ( x2 != right ) {
                    auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[yy][x22] );
                    pair.data[0] = index;
                    reinterpret_cast<buffer_row *>( address )[yy][x22] = to_bit_container( pair );
                }

                std::fill( reinterpret_cast<buffer_row *>( address )[yy] + left2, reinterpret_cast<buffer_row *>( address )[yy] + right2, fillPair );
            }
        }

        static void rect( int x1, int y1, int x2, int y2, pixel_type index ) noexcept {
            const auto fillPair = to_bit_container( pixel_pair { index, index } );
            const auto left = x1 + ( x1 % 2 );
            const auto right = x2 - ( x2 % 2 );

            const auto x12 = x1 / 2;
            auto x22 = x2 / 2;
            const auto left2 = left / 2;
            const auto right2 = right / 2;

            y2 -= 1;

            std::fill( reinterpret_cast<buffer_row *>( address )[y1] + left2, reinterpret_cast<buffer_row *>( address )[y1] + right2, fillPair );
            std::fill( reinterpret_cast<buffer_row *>( address )[y2] + left2, reinterpret_cast<buffer_row *>( address )[y2] + right2, fillPair );

            if ( x1 != left ) {
                auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y1][x12] );
                pair.data[1] = index;
                reinterpret_cast<buffer_row *>( address )[y1][x12] = to_bit_container( pair );

                pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y2][x12] );
                pair.data[1] = index;
                reinterpret_cast<buffer_row *>( address )[y2][x12] = to_bit_container( pair );
            }

            if ( x2 != right ) {
                auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y1][x22] );
                pair.data[0] = index;
                reinterpret_cast<buffer_row *>( address )[y1][x22] = to_bit_container( pair );

                pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y2][x22] );
                pair.data[0] = index;
                reinterpret_cast<buffer_row *>( address )[y2][x22] = to_bit_container( pair );
            } else {
                x22 -= 1;
            }

            for ( int yy = y1 + 1; yy < y2; ++yy ) {
                auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[yy][x12] );
                pair.data[x1 != left] = index;
                reinterpret_cast<buffer_row *>( address )[yy][x12] = to_bit_container( pair );

                pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[yy][x22] );
                pair.data[x2 == right] = index;
                reinterpret_cast<buffer_row *>( address )[yy][x22] = to_bit_container( pair );
            }
        }

        static void line( int x1, int y1, int x2, int y2, pixel_type index ) noexcept {
            int xstep;
            int dx;
            if ( x1 > x2 ) {
                xstep = -1;
                dx = x1 - x2;
            } else {
                xstep = +1;
                dx = x2 - x1;
            }

            int ystep;
            int dy;
            if ( y1 > y2 ) {
                ystep = -1;
                dy = y1 - y2;
            } else {
                ystep = +1;
                dy = y2 - y1;
            }

            if ( dy == 0 ) {
                const auto left = x1 + ( x1 % 2 );
                const auto right = x2 - ( x2 % 2 );

                if ( x1 != left ) {
                    const auto x12 = x1 / 2;

                    auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y1][x12] );
                    pair.data[1] = index;
                    reinterpret_cast<buffer_row *>( address )[y1][x12] = to_bit_container( pair );
                }

                if ( x2 != right ) {
                    const auto x22 = x2 / 2;

                    auto pair = from_bit_container<pixel_pair>( reinterpret_cast<buffer_row *>( address )[y1][x22] );
                    pair.data[0] = index;
                    reinterpret_cast<buffer_row *>( address )[y1][x22] = to_bit_container( pair );
                }

                const auto fillPair = to_bit_container( pixel_pair { index, index } );
                const auto left2 = left / 2;
                const auto right2 = right / 2;

                std::fill( reinterpret_cast<buffer_row *>( address )[y1] + left2, reinterpret_cast<buffer_row *>( address )[y1] + right2, fillPair );
            } else if ( dx == 0 ) {
                for ( int yy = y1; yy < y2; ++yy ) {
                    put_pixel( x1, yy, index );
                }
            } else if ( dx >= dy ) {
                int dd = 2 * dy - dx;
                for ( int ii = 0; ii <= dx; ++ii ) {
                    put_pixel( x1, y1, index );
                    if ( dd >= 0 ) {
                        dd -= 2 * dx;
                        y1 += ystep;
                    }

                    dd += 2 * dy;
                    x1 += xstep;
                }
            } else {
                int dd = 2 * dx - dy;
                for ( int ii = 0; ii <= dy; ++ii ) {
                    put_pixel( x1, y1, index );
                    if ( dd >= 0 ) {
                        dd -= 2 * dy;
                        x1 += xstep;
                    }

                    dd += 2 * dx;
                    y1 += ystep;
                }
            }
        }

        static void clear() noexcept {
            clear_to_color( 0 );
        }

        template <typename BitmapDef, typename = typename std::enable_if<std::is_same<typename BitmapDef::pixel_type, pixel_type>::value, void>::type>
        static void blit( const bitmap<BitmapDef>& source, int srcX, int srcY, int dstX, int dstY, int width, int height ) noexcept {
            for ( int yy = 0; yy < height; ++yy ) {
                // TODO : pixel_pair

                for ( int xx = 0; xx < width; ++xx ) {
                    put_pixel( dstX + xx, dstY + yy, source.get_pixel( srcX + xx, srcY + yy ) );
                }
            }
        }
    };

    using frame_buffer_0 = frame_buffer<0x6000000>;
    using frame_buffer_1 = frame_buffer<0x600a000>;

    struct display_control : gba::display_control {
        constexpr display_control() noexcept : gba::display_control { 4, false, false, false, false, false, false,
                                                                      false, false, false, false, false, false,
                                                                      false } {}

        constexpr auto& page_select( const bool value ) noexcept {
            gba::display_control::page_select = value;
            return *this;
        }

        constexpr auto& object_horizontal_blank_access( const bool value ) noexcept {
            gba::display_control::object_horizontal_blank_access = value;
            return *this;
        }

        constexpr auto& object_mapping_linear( const bool value ) noexcept {
            gba::display_control::object_mapping_linear = value;
            return *this;
        }

        constexpr auto& force_blank( const bool value ) noexcept {
            gba::display_control::force_blank = value;
            return *this;
        }

        constexpr auto& layer_background_2( const bool value ) noexcept {
            gba::display_control::layer_background_2 = value;
            return *this;
        }

        constexpr auto& layer_object( const bool value ) noexcept {
            gba::display_control::layer_object = value;
            return *this;
        }

        constexpr auto& window_0( const bool value ) noexcept {
            gba::display_control::window_0 = value;
            return *this;
        }

        constexpr auto& window_1( const bool value ) noexcept {
            gba::display_control::window_1 = value;
            return *this;
        }

        constexpr auto& window_object( const bool value ) noexcept {
            gba::display_control::window_object = value;
            return *this;
        }

    protected:
        using gba::display_control::mode;
        using gba::display_control::game_boy;
        using gba::display_control::layer_background_0;
        using gba::display_control::layer_background_1;
        using gba::display_control::layer_background_3;
    };
};

} // gba

#endif // define GBAXX_VIDEO_MODE4_HPP
