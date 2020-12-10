#ifndef GBAXX_FIXED_POINT_MAKE_HPP
#define GBAXX_FIXED_POINT_MAKE_HPP

#include <limits>
#include <type_traits>

#include <gba/types/fixed_point.hpp>
#include <gba/types/int_type.hpp>

namespace gba {

template <int IntegerDigits, int FractionalDigits = 0, class Narrowest = signed>
using make_fixed = fixed_point<typename set_digits<Narrowest, IntegerDigits + FractionalDigits>::type, -FractionalDigits>;

template <int IntegerDigits, int FractionalDigits = 0, class Narrowest = unsigned>
using make_ufixed = make_fixed<IntegerDigits, FractionalDigits, typename std::make_unsigned<Narrowest>::type>;

} // gba

#endif // define GBAXX_FIXED_POINT_MAKE_HPP
