#ifndef GBAXX_DRAWING_TILE_BITMAP_HPP
#define GBAXX_DRAWING_TILE_BITMAP_HPP

#include <algorithm>

#include <gba/drawing/bitmap.hpp>
#include <gba/types/int_type.hpp>

namespace gba {

struct tile_def_4bpp {
    using pixel_type = uint8;

    std::array<pixel_type, 32> data;
};

static_assert( sizeof( tile_def_4bpp ) == 32, "tile_def_4bpp must be tightly packed" );

using tile_bitmap_4bpp = bitmap<tile_def_4bpp>;

struct tile_def_8bpp {
    using pixel_type = uint8;

    std::array<pixel_type, 64> data;
};

static_assert( sizeof( tile_def_8bpp ) == 64, "tile_def_8bpp must be tightly packed" );

using tile_bitmap_8bpp = bitmap<tile_def_8bpp>;

} // gba

#endif // define GBAXX_DRAWING_TILE_BITMAP_HPP
