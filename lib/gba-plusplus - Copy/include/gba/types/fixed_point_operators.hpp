#ifndef GBAXX_FIXED_POINT_OPERATORS_HPP
#define GBAXX_FIXED_POINT_OPERATORS_HPP

#include <algorithm>

#include <gba/types/fixed_point.hpp>

template <class RhsRep, int RhsExponent>
constexpr auto operator -( const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept -> gba::fixed_point<decltype( -rhs.data() ), RhsExponent> {
    using result_type = gba::fixed_point<decltype( -rhs.data() ), RhsExponent>;

    return result_type::from_data( -rhs.data() );
}

template <class LhsRep, int LhsExponent, class RhsRep, int RhsExponent>
constexpr auto operator +( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    using larger = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast,
            typename gba::uint_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast>;
    constexpr auto exponent = ( LhsExponent + RhsExponent ) / 2;

    return gba::fixed_point<larger, exponent>::from_data( gba::fixed_point<larger, exponent>( lhs ).data() + gba::fixed_point<larger, exponent>( rhs ).data() );
}

template <class LhsRep, int LhsExponent, class RhsRep, int RhsExponent>
constexpr auto operator -( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    using larger = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast,
            typename gba::uint_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast>;
    constexpr auto exponent = ( LhsExponent + RhsExponent ) / 2;

    return gba::fixed_point<larger, exponent>::from_data( gba::fixed_point<larger, exponent>( lhs ).data() - gba::fixed_point<larger, exponent>( rhs ).data() );
}

template <class LhsRep, int LhsExponent, class RhsRep, int RhsExponent>
constexpr auto operator *( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    using larger = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::numeric_limits<LhsRep>::digits + std::numeric_limits<RhsRep>::digits>::fast,
            typename gba::uint_type<std::numeric_limits<LhsRep>::digits + std::numeric_limits<RhsRep>::digits>::fast>;
    using word = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast,
            typename gba::uint_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast>;

    constexpr auto max_exponent = std::max( LhsExponent, RhsExponent );
    constexpr auto sum_exponent = LhsExponent + RhsExponent;

    const auto result = gba::fixed_point<larger, sum_exponent>::from_data( gba::fixed_point<larger, LhsExponent>( lhs ).data() * gba::fixed_point<larger, RhsExponent>( rhs ).data() );

    return gba::fixed_point<word, max_exponent>( result );
}

template <class LhsRep, int LhsExponent, class RhsRep, int RhsExponent>
constexpr auto operator /( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    using larger = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::numeric_limits<LhsRep>::digits + std::numeric_limits<RhsRep>::digits>::fast,
            typename gba::uint_type<std::numeric_limits<LhsRep>::digits + std::numeric_limits<RhsRep>::digits>::fast>;
    using word = std::conditional_t<std::is_signed_v<LhsRep> || std::is_signed_v<RhsRep>,
            typename gba::int_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast,
            typename gba::uint_type<std::max( std::numeric_limits<LhsRep>::digits, std::numeric_limits<RhsRep>::digits )>::fast>;

    constexpr auto sum_exponent = LhsExponent + RhsExponent;

    return gba::fixed_point<word, LhsExponent>::from_data( gba::fixed_point<larger, sum_exponent>( lhs ).data() / static_cast<larger>( rhs.data() ) );
}

template <class LhsRep, int LhsExponent, class RhsInteger, typename = std::enable_if_t<std::numeric_limits<RhsInteger>::is_integer>>
constexpr auto operator +( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const RhsInteger& rhs ) noexcept {
    return lhs + gba::fixed_point<RhsInteger> { rhs };
}

template <class LhsRep, int LhsExponent, class RhsInteger, typename = std::enable_if_t<std::numeric_limits<RhsInteger>::is_integer>>
constexpr auto operator -( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const RhsInteger& rhs ) noexcept {
    return lhs - gba::fixed_point<RhsInteger> { rhs };
}

template <class LhsRep, int LhsExponent, class RhsInteger, typename = std::enable_if_t<std::numeric_limits<RhsInteger>::is_integer>>
constexpr auto operator *( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const RhsInteger& rhs ) noexcept {
    return lhs * gba::fixed_point<RhsInteger> { rhs };
}

template <class LhsRep, int LhsExponent, class RhsInteger, typename = std::enable_if_t<std::numeric_limits<RhsInteger>::is_integer>>
constexpr auto operator /( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const RhsInteger& rhs ) noexcept {
    return lhs / gba::fixed_point<RhsInteger> { rhs };
}

template <class LhsInteger, class RhsRep, int RhsExponent, typename = std::enable_if_t<std::numeric_limits<LhsInteger>::is_integer>>
constexpr auto operator +( const LhsInteger& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    return gba::fixed_point<LhsInteger, 0> { lhs } + rhs;
}

template <class LhsInteger, class RhsRep, int RhsExponent, typename = std::enable_if_t<std::numeric_limits<LhsInteger>::is_integer>>
constexpr auto operator -( const LhsInteger& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    return gba::fixed_point<LhsInteger, 0> { lhs } - rhs;
}

template <class LhsInteger, class RhsRep, int RhsExponent, typename = std::enable_if_t<std::numeric_limits<LhsInteger>::is_integer>>
constexpr auto operator *( const LhsInteger& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    return gba::fixed_point<LhsInteger, 0> { lhs } * rhs;
}

template <class LhsInteger, class RhsRep, int RhsExponent, typename = std::enable_if_t<std::numeric_limits<LhsInteger>::is_integer>>
constexpr auto operator /( const LhsInteger& lhs, const gba::fixed_point<RhsRep, RhsExponent>& rhs ) noexcept {
    return gba::fixed_point<LhsInteger, 0> { lhs } / rhs;
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr auto operator +=( gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs = lhs + rhs;
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr auto operator -=( gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs = lhs - rhs;
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr auto operator *=( gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs = lhs * rhs;
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr auto operator /=( gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs = lhs / rhs;
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator <( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() < gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator <=( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() <= gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator >( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() > gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator >=( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() >= gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator ==( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() == gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

template <class LhsRep, int LhsExponent, class Rhs>
constexpr bool operator !=( const gba::fixed_point<LhsRep, LhsExponent>& lhs, const Rhs& rhs) noexcept {
    return lhs.data() != gba::fixed_point<LhsRep, LhsExponent>( rhs ).data();
}

#endif // define GBAXX_FIXED_POINT_OPERATORS_HPP
