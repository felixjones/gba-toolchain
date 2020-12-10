#ifndef GBAXX_TYPES_COLOR_HPP
#define GBAXX_TYPES_COLOR_HPP

#include <gba/types/int_type.hpp>

namespace gba {
namespace color {

struct rgb555 {
    uint16 red : 5;
    uint16 green : 5;
    uint16 blue : 5;
    uint16 : 1;
};

static_assert( sizeof( rgb555 ) == 2, "rgb555 must be tightly packed" );

} // color
} // gba

#endif // define GBAXX_TYPES_COLOR_HPP
