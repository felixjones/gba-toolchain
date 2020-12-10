#ifndef GBAXX_TYPES_INT_TYPE_HPP
#define GBAXX_TYPES_INT_TYPE_HPP

#include <cstdint>
#include <type_traits>

namespace gba {

template <unsigned Bits>
struct int_type {
    static_assert( Bits > 1, "int_type Bits cannot be less than two" );

    using type = typename std::conditional<Bits <= 8, std::int8_t, typename std::conditional<Bits <= 16, std::int16_t, typename std::conditional<Bits <= 32, std::int32_t, std::int64_t>::type>::type>::type;
    using least = typename std::conditional<Bits <= 8, std::int_least8_t, typename std::conditional<Bits <= 16, std::int_least16_t, typename std::conditional<Bits <= 32, std::int_least32_t, std::int_least64_t>::type>::type>::type;
    using fast = typename std::conditional<Bits <= 8, std::int_fast8_t, typename std::conditional<Bits <= 16, std::int_fast16_t, typename std::conditional<Bits <= 32, std::int_fast32_t, std::int_fast64_t>::type>::type>::type;

    static constexpr fast min() noexcept {
        return Bits == 2 ? -2 : 2 * int_type<Bits - 1>::min();
    }

    static constexpr fast max() noexcept {
        return -min() - 1;
    }
};

template <unsigned int Bits>
struct uint_type {
    static_assert( Bits > 0, "uint_type Bits cannot be zero" );

    using type = typename std::conditional<Bits <= 8, std::uint8_t, typename std::conditional<Bits <= 16, std::uint16_t, typename std::conditional<Bits <= 32, std::uint32_t, std::uint64_t>::type>::type>::type;
    using least = typename std::conditional<Bits <= 8, std::uint_least8_t, typename std::conditional<Bits <= 16, std::uint_least16_t, typename std::conditional<Bits <= 32, std::uint_least32_t, std::uint_least64_t>::type>::type>::type;
    using fast = typename std::conditional<Bits <= 8, std::uint_fast8_t, typename std::conditional<Bits <= 16, std::uint_fast16_t, typename std::conditional<Bits <= 32, std::uint_fast32_t, std::uint_fast64_t>::type>::type>::type;

    static constexpr fast min() noexcept {
        return 0;
    }

    static constexpr fast max() noexcept {
        return int_type<Bits + 1>::max();
    }
};

using int8 = int_type<8>::type;
using int16 = int_type<16>::type;
using int32 = int_type<32>::type;

using uint8 = uint_type<8>::type;
using uint16 = uint_type<16>::type;
using uint32 = uint_type<32>::type;

namespace detail {

    template <int MinNumDigits, class Smaller, class T>
    struct enable_for_range : std::enable_if<MinNumDigits <= std::numeric_limits<T>::digits && std::numeric_limits<Smaller>::digits < MinNumDigits> {};

    template <int MinNumDigits, class Smallest>
    struct enable_for_range<MinNumDigits, void, Smallest> : std::enable_if<MinNumDigits <= std::numeric_limits<Smallest>::digits> {};

    template <int MinNumDigits, class Enable = void>
    struct set_digits_signed;

    template <int MinNumDigits>
    struct set_digits_signed<MinNumDigits, typename detail::enable_for_range<MinNumDigits, void, std::int8_t>::type> {
        using type = int8;
    };

    template <int MinNumDigits>
    struct set_digits_signed<MinNumDigits, typename detail::enable_for_range<MinNumDigits, std::int8_t, std::int16_t>::type> {
        using type = int16;
    };

    template <int MinNumDigits>
    struct set_digits_signed<MinNumDigits, typename detail::enable_for_range<MinNumDigits, std::int16_t, std::int32_t>::type> {
        using type = int32;
    };

    template <int MinNumDigits, class Enable = void>
    struct set_digits_unsigned;

    template <int MinNumDigits>
    struct set_digits_unsigned<MinNumDigits, typename detail::enable_for_range<MinNumDigits, void, std::uint8_t>::type> {
        using type = uint8;
    };

    template <int MinNumDigits>
    struct set_digits_unsigned<MinNumDigits, typename detail::enable_for_range<MinNumDigits, std::uint8_t, std::uint16_t>::type> {
        using type = uint16;
    };

    template <int MinNumDigits>
    struct set_digits_unsigned<MinNumDigits, typename detail::enable_for_range<MinNumDigits, std::uint16_t, std::uint32_t>::type> {
        using type = uint32;
    };

    template <class Integer, int MinNumDigits>
    using set_digits_integer = std::conditional_t<std::numeric_limits<Integer>::is_signed, set_digits_signed<MinNumDigits>, set_digits_unsigned<MinNumDigits>>;

} // detail

template <class T, int Digits, class Enable = void>
struct set_digits;

template <class T, int Digits>
struct set_digits<T, Digits, std::enable_if_t<std::is_integral<T>::value>> : detail::set_digits_integer<T, Digits> {};

} // gba

#endif // define GBAXX_TYPES_INT_TYPE_HPP
