#ifndef GBAXX_VIDEO_CHARACTER_BLOCK_HPP
#define GBAXX_VIDEO_CHARACTER_BLOCK_HPP

#include <gba/drawing/tile_bitmap.hpp>
#include <gba/io/bufmap.hpp>
#include <gba/types/int_type.hpp>

namespace gba {

using character_block_4bpp = bufmap_banked<0x6000000, tile_bitmap_4bpp, 512>;
using character_block_8bpp = bufmap_banked<0x6000000, tile_bitmap_8bpp, 256>;

} // gba

#endif // define GBAXX_VIDEO_CHARACTER_BLOCK_HPP
