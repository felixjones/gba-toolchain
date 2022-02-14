/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#ifndef FIXED_HPP
#define FIXED_HPP

#include <concepts>
#include <cstdint>
#include <agbabi.h>

struct fixed_type {
    using data_type = std::int32_t;
    
    static const auto exponent = 16;

    constexpr fixed_type() noexcept : data {} {}

    constexpr fixed_type(std::integral auto x) noexcept : data { x << exponent } {}

    consteval fixed_type(std::floating_point auto x) noexcept : data { static_cast<data_type>(x * (1 << exponent)) } {}

    static constexpr auto from_raw(const data_type x) noexcept  {
        fixed_type y;
        y.data = x;
        return y;
    }

    explicit operator float() const noexcept {
        return static_cast<float>(data) / (1 << exponent);
    }

    constexpr explicit operator int() const noexcept {
        return data >> exponent;
    }

    constexpr auto operator +(std::integral auto x) const noexcept {
        return from_raw(data + (x << exponent));
    }

    constexpr auto operator +(const fixed_type o) const noexcept {
        return from_raw(data + o.data);
    }

    constexpr auto& operator +=(const fixed_type o) noexcept {
        data += o.data;
        return *this;
    }

    constexpr auto& operator -=(const fixed_type o) noexcept {
        data -= o.data;
        return *this;
    }

    constexpr auto operator -(std::integral auto x) const noexcept {
        return from_raw(data - (x << exponent));
    }

    constexpr auto operator -(const fixed_type o) const noexcept {
        return from_raw(data - o.data);
    }

    constexpr auto& operator -=(std::integral auto x) noexcept {
        data -= (x << exponent);
        return *this;
    }

    constexpr auto operator *(std::integral auto x) const noexcept {
        return from_raw(static_cast<std::int64_t>(data) * x);
    }

    constexpr auto operator *(const fixed_type o) const noexcept {
        return from_raw(static_cast<data_type>((static_cast<std::int64_t>(data) * o.data) >> exponent));
    }

    constexpr auto operator /(const fixed_type o) const noexcept {
        const auto dataLL = static_cast<std::int64_t>(data) << exponent;
        if (std::is_constant_evaluated()) {
            return from_raw(static_cast<data_type>(dataLL / o.data));
        }
        return from_raw(static_cast<data_type>(__agbabi_uluidiv(dataLL, o.data)));
    }

    constexpr auto operator -() const noexcept {
        return from_raw(-data);
    }

    constexpr auto operator <<(std::integral auto x) const noexcept {
        return from_raw(data << x);
    }

    constexpr auto operator <(std::integral auto x) const noexcept {
        return (data >> exponent) < x;
    }

    constexpr auto operator >(std::integral auto x) const noexcept {
        return data > (x << exponent);
    }

    constexpr auto operator !() const noexcept {
        return data == 0;
    }

    constexpr auto operator <(const fixed_type o) const noexcept {
        return data < o.data;
    }

    data_type data;
};

constexpr auto operator +(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw((x << fixed_type::exponent) + y.data);
}

constexpr auto operator -(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw((x << fixed_type::exponent) - y.data);
}

constexpr auto operator *(std::integral auto x, const fixed_type y) noexcept {
    return fixed_type::from_raw(x * y.data);
}

constexpr auto operator /(std::integral auto x, const fixed_type y) noexcept {
    const auto dataLL = static_cast<std::int64_t>(x) << (fixed_type::exponent * 2);
    if (std::is_signed_v<decltype(x)> || std::is_constant_evaluated()) {
        return fixed_type::from_raw(static_cast<fixed_type::data_type>(dataLL / y.data));
    }
    return fixed_type::from_raw(static_cast<fixed_type::data_type>(__agbabi_uluidiv(dataLL, y.data)));
}

inline fixed_type fixed_floor(const fixed_type x) noexcept {
    return fixed_type::from_raw(x.data & static_cast<fixed_type::data_type>(0xffffffffu << fixed_type::exponent));
}

inline fixed_type fixed_abs(const fixed_type x) noexcept {
    return fixed_type::from_raw(x.data < 0 ? -x.data : x.data);
}

inline fixed_type fixed_frac(const fixed_type x) noexcept {
    return fixed_type::from_raw(x.data & ((1 << fixed_type::exponent) - 1));
}

inline auto fixed_negative(const fixed_type x) noexcept {
    return x.data < 0;
}

#endif // define fixed.hpp
