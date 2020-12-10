#ifndef GBAXX_FIXED_POINT_FUNCS_HPP
#define GBAXX_FIXED_POINT_FUNCS_HPP

#if !defined( __has_builtin )
#define __has_builtin( x )  0
#endif

#if __cpp_lib_is_constant_evaluated
#include <type_traits>
#endif

#if __cpp_lib_is_constant_evaluated
#define gbaxx_fixed_point_funcs_constant( x )   std::is_constant_evaluated()
#elif __has_builtin( __builtin_constant_p )
#define gbaxx_fixed_point_funcs_constant( x )   __builtin_constant_p( x )
#else
#define gbaxx_fixed_point_funcs_constant
#endif

#include <algorithm>

#include <gba/bios/sqrt.hpp>
#include <gba/types/fixed_point.hpp>
#include <gba/types/fixed_point_make.hpp>
#include <gba/types/fixed_point_operators.hpp>

namespace gba {
namespace detail {

constexpr auto sin_bam16( int32 x ) noexcept {
    x = static_cast<uint32>( x ) << 17;
    if ( static_cast<int32>( x ^ ( static_cast<uint32>( x ) << 1 ) ) < 0 ) {
        x = ( 1 << 31 ) - x;
    }
    x = x >> 17;
    return make_fixed<19, 12>::from_data( x * ( ( 3 << 15 ) - ( x * x >> 11 ) ) >> 17 );
}

template <class Rep, int Exponent>
constexpr int32 radian_to_bam16( const fixed_point<Rep, Exponent>& radian ) noexcept {
    constexpr auto radTo16 = fixed_point<Rep, Exponent>( 16384.0 / 3.14159265358979323846264338327950288 );
    return static_cast<int32>( radian * radTo16 );
}

template <class Rep>
constexpr Rep sqrt_bit( Rep n, Rep bit ) noexcept {
    if ( bit > n ) {
        return sqrt_bit<Rep>( n, bit >> 2 );
    } else {
        return bit;
    }
}

template <class Rep>
constexpr auto sqrt_bit( Rep n ) noexcept {
    return sqrt_bit<Rep>( n, Rep( 1 ) << ( sizeof( Rep ) * 8 - 2 ) );
}

template <class Rep>
constexpr Rep sqrt_solve3( Rep n, Rep bit, Rep result ) noexcept {
    if ( bit != 0 ) {
        if ( n >= result + bit ) {
            return sqrt_solve3<Rep>( static_cast<Rep>( n - ( result + bit ) ), bit >> 2, static_cast<Rep>( ( result >> 1 ) + bit ) );
        } else {
            return sqrt_solve3<Rep>( n, bit >> 2, result >> 1 );
        }
    } else {
        return result;
    }
}

template <class Rep>
constexpr auto sqrt_solve1( Rep n ) noexcept {
    return sqrt_solve3<Rep>( n, sqrt_bit<Rep>( n ), 0 );
}

} // detail

template <class Rep, int Exponent>
constexpr auto sqrt( const fixed_point<Rep, Exponent>& x ) noexcept {
    using larger = typename gba::uint_type<std::numeric_limits<Rep>::digits>::fast;
    constexpr auto larger_exponent = Exponent - ( std::numeric_limits<larger>::digits - std::numeric_limits<Rep>::digits );

    if ( gbaxx_fixed_point_funcs_constant( x.data() ) ) {
        return fixed_point<uint32, larger_exponent / 2>::from_data( detail::sqrt_solve1( fixed_point<larger, larger_exponent>( x ).data() ) );
    }

    return fixed_point<uint32, larger_exponent / 2>::from_data( bios::sqrt( std::move( fixed_point<larger, larger_exponent>( x ).data() ) ) );
}

template <class Rep, int Exponent>
constexpr auto sin( const fixed_point<Rep, Exponent>& radian ) noexcept {
    return detail::sin_bam16( detail::radian_to_bam16( radian ) );
}

template <class Rep, int Exponent>
constexpr auto cos( const fixed_point<Rep, Exponent>& radian ) noexcept {
    return detail::sin_bam16( detail::radian_to_bam16( radian ) + 0x2000 );
}

} // gba

#endif // define GBAXX_FIXED_POINT_FUNCS_HPP
