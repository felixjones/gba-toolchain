#ifndef GBAXX_VIDEO_MODE3_HPP
#define GBAXX_VIDEO_MODE3_HPP

#include <algorithm>

#include <gba/drawing/bitmap.hpp>
#include <gba/types/color.hpp>
#include <gba/video/mode.hpp>

namespace gba {

/**
 *
 */
template <>
struct mode<3> {
    /**
     *
     */
    struct frame_buffer {
        static constexpr auto address = 0x6000000;

        using pixel_type = color::rgb555;
        using buffer_row = pixel_type[240];

        static void put_pixel( int x, int y, pixel_type color ) noexcept {
            reinterpret_cast<buffer_row *>( address )[y][x] = color;
        }

        [[nodiscard]]
        static pixel_type get_pixel( int x, int y ) noexcept {
            return reinterpret_cast<buffer_row *>( address )[y][x];
        }

        static void clear_to_color( pixel_type color ) noexcept {
            struct pixel_pair {
                pixel_type data[2];
            };
            std::fill( reinterpret_cast<pixel_pair *>( address ), reinterpret_cast<pixel_pair *>( address ) + ( 240 * 80 ), pixel_pair { color, color } );
        }

        static void rect_fill( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
            for ( int yy = y1; yy < y2; ++yy ) {
                std::fill( reinterpret_cast<buffer_row *>( address )[yy] + x1, reinterpret_cast<buffer_row *>( address )[yy] + x2, color );
            }
        }

        static void rect( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
            std::fill( reinterpret_cast<buffer_row *>( address )[y1] + x1, reinterpret_cast<buffer_row *>( address )[y1] + x2, color );
            std::fill( reinterpret_cast<buffer_row *>( address )[y2 - 1] + x1, reinterpret_cast<buffer_row *>( address )[y2 - 1] + x2, color );
            for ( int yy = y1 + 1; yy < y2 - 1; ++yy ) {
                reinterpret_cast<buffer_row *>( address )[yy][x1] = color;
                reinterpret_cast<buffer_row *>( address )[yy][x2 - 1] = color;
            }
        }

        static void line( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
            auto * dst = reinterpret_cast<buffer_row *>( address )[y1] + x1;

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
                ystep = -240;
                dy = y1 - y2;
            } else {
                ystep = +240;
                dy = y2 - y1;
            }

            if ( dy == 0 ) {
                std::fill( dst, dst + dx, color );
            } else if ( dx == 0 ) {
                for ( int yy = 0; yy < dy; ++yy ) {
                    dst[yy * ystep] = color;
                }
            } else if ( dx >= dy ) {
                int dd = 2 * dy - dx;
                for ( int ii = 0; ii <= dx; ++ii ) {
                    *dst = color;
                    if ( dd >= 0 ) {
                        dd -= 2 * dx;
                        dst += ystep;
                    }

                    dd += 2 * dy;
                    dst += xstep;
                }
            } else {
                int dd = 2 * dx - dy;
                for ( int ii = 0; ii <= dy; ++ii ) {
                    *dst = color;
                    if ( dd >= 0 ) {
                        dd -= 2 * dy;
                        dst += xstep;
                    }

                    dd += 2 * dx;
                    dst += ystep;
                }
            }
        }

        static void clear() noexcept {
            clear_to_color( {} );
        }
    };

    /**
     *
     */
    struct display_control : gba::display_control {
        constexpr display_control() noexcept : gba::display_control { 3, false, false, false, false, false, false,
                                                                      false, false, false, false, false, false,
                                                                      false } {}

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
        using gba::display_control::page_select;
        using gba::display_control::layer_background_0;
        using gba::display_control::layer_background_1;
        using gba::display_control::layer_background_3;
    };
};


} // gba

#endif // define GBAXX_VIDEO_MODE3_HPP
