#ifndef GBAXX_DRAWING_BITMAP_HPP
#define GBAXX_DRAWING_BITMAP_HPP

#include <gba/types/int_type.hpp>

namespace gba {

template <typename BitmapDef>
struct bitmap : BitmapDef {
    using pixel_type = typename BitmapDef::pixel_type;

    void put_pixel( int x, int y, pixel_type color ) noexcept {
        BitmapDef::put_pixel( x, y, color );
    }

    [[nodiscard]]
    pixel_type get_pixel( int x, int y ) const noexcept {
        return BitmapDef::get_pixel( x, y );
    }

    void clear_to_color( pixel_type color ) noexcept {
        BitmapDef::clear_to_color( color );
    }

    void rect_fill( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
        BitmapDef::rect_fill( x1, y1, x2, y2, color );
    }

    void rect( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
        BitmapDef::rect( x1, y1, x2, y2, color );
    }

    void line( int x1, int y1, int x2, int y2, pixel_type color ) noexcept {
        BitmapDef::line( x1, y1, x2, y2, color );
    }

    void clear() noexcept {
        BitmapDef::clear();
    }
};

template <typename PixelType, unsigned Width, unsigned Height>
struct image_def {
    using pixel_type = PixelType;
    static constexpr auto width = Width;
    static constexpr auto height = Height;

    [[nodiscard]]
    pixel_type get_pixel( int x, int y ) const noexcept {
        return address[( y * Width ) + x];
    }

    const pixel_type * address;
};

template <typename PixelType, unsigned Width, unsigned Height>
using image = bitmap<image_def<PixelType, Width, Height>>;

} // gba

#endif // define GBAXX_DRAWING_BITMAP_HPP
