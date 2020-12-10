#ifndef GBAXX_GBA_HPP
#define GBAXX_GBA_HPP

#include <gba/bios/halt.hpp>

#include <gba/drawing/bitmap.hpp>
#include <gba/drawing/tile_bitmap.hpp>

#include <gba/interrupt/flags.hpp>

#include <gba/io/bit_container.hpp>
#include <gba/io/bufmap.hpp>
#include <gba/io/ioguard.hpp>
#include <gba/io/memmap.hpp>
#include <gba/io/registers.hpp>

#include <gba/keypad/key_handler.hpp>
#include <gba/keypad/keys.hpp>

#include <gba/types/color.hpp>
#include <gba/types/fixed_point.hpp>
#include <gba/types/fixed_point_funcs.hpp>
#include <gba/types/fixed_point_make.hpp>
#include <gba/types/fixed_point_operators.hpp>
#include <gba/types/int_type.hpp>

#include <gba/video/background_affine.hpp>
#include <gba/video/background_control.hpp>
#include <gba/video/background_regular.hpp>
#include <gba/video/character_block.hpp>
#include <gba/video/display_control.hpp>
#include <gba/video/display_status.hpp>
#include <gba/video/mode.hpp>
#include <gba/video/mode0.hpp>
#include <gba/video/mode1.hpp>
#include <gba/video/mode2.hpp>
#include <gba/video/mode3.hpp>
#include <gba/video/mode4.hpp>
#include <gba/video/mode5.hpp>
#include <gba/video/object_attribute.hpp>
#include <gba/video/palette.hpp>
#include <gba/video/screen_block.hpp>

#endif // define GBAXX_GBA_HPP
