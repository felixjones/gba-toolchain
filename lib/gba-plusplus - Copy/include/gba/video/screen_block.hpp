#ifndef GBAXX_VIDEO_SCREEN_BLOCK_HPP
#define GBAXX_VIDEO_SCREEN_BLOCK_HPP

#include <gba/io/bufmap.hpp>
#include <gba/types/int_type.hpp>

namespace gba {

struct tile_entry_regular {
    uint16 index : 10;
    bool flip_x : 1, flip_y : 1;
    uint16 palette_bank : 4;
};

static_assert( sizeof( tile_entry_regular ) == 2, "tile_entry_regular must be tightly packed" );

struct tile_entry_affine {
    uint8 index;
};

static_assert( sizeof( tile_entry_affine ) == 1, "tile_entry_affine must be tightly packed" );

using screen_block_regular = bufmap_banked<0x6000000, tile_entry_regular, 1024>;
using screen_block_affine = bufmap_banked<0x6000000, tile_entry_affine, 1024>;

} // gba

#endif // define GBAXX_VIDEO_SCREEN_BLOCK_HPP
