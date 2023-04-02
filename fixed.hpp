#pragma once

#include <concepts>
#include <numbers>

#include <gcem.hpp>

struct fixed {
    constexpr fixed() noexcept = default;

    template <std::floating_point T>
    constexpr explicit fixed(T t) noexcept : data{static_cast<int>(gcem::round(t * T(0x10000)))} {}

    template <std::integral T>
    constexpr explicit fixed(T t) noexcept : data{static_cast<int>(t * 0x10000)} {}

    template <std::integral T>
    constexpr fixed(std::nullptr_t, T t) noexcept : data{static_cast<int>(t)} {}

    template <std::integral T>
    constexpr fixed& operator=(T t) noexcept {
        data = t * 0x10000;
        return *this;
    }

    constexpr explicit operator int() const noexcept {
        return data >> 16;
    }

    int data;
};

namespace {

template <typename T>
concept Arithmetic = std::is_arithmetic_v<T>;

template <Arithmetic T>
constexpr auto operator<=>(fixed lhs, T rhs) noexcept {
    return lhs.data <=> fixed(rhs).data;
}

template <Arithmetic T>
constexpr auto operator-(T lhs, fixed rhs) noexcept -> fixed {
    return {nullptr, fixed(lhs).data - rhs.data};
}

template <Arithmetic T>
constexpr auto operator+(fixed lhs, T rhs) noexcept -> fixed {
    return {nullptr, lhs.data + fixed(rhs).data};
}

template <Arithmetic T>
constexpr auto operator/(T lhs, fixed rhs) noexcept -> fixed {
    return {nullptr, static_cast<int>((double(lhs) * 0x100000000LL) / rhs.data)};
}

constexpr auto operator/(fixed lhs, fixed rhs) noexcept -> fixed {
    return {nullptr, (static_cast<long long int>(lhs.data) * rhs.data) >> 16};
}

template <std::floating_point T>
constexpr auto normalize_radian(T radian) noexcept -> T {
    constexpr auto two_pi = 2 * std::numbers::pi_v<T>;

    while (radian < 0) {
        radian += two_pi;
    }
    while (radian >= two_pi) {
        radian -= two_pi;
    }
    return radian;
}

}

struct angle {
    constexpr angle() noexcept = default;

    template <std::floating_point T>
    constexpr explicit angle(T radian) noexcept : data{static_cast<int>(normalize_radian(radian) / (2 * std::numbers::pi_v<double>) * 0xffffffffLLU)} {}

    template <std::integral T>
    constexpr angle(std::nullptr_t, T t) noexcept : data{static_cast<int>(t)} {}

    template <std::size_t Bits, std::integral T>
    static constexpr angle from_int(T t) noexcept {
        return {nullptr, int(t << (32 - Bits))};
    }

    template <std::size_t Bits>
    constexpr auto to_int() const noexcept {
        return static_cast<unsigned int>(data) >> (32 - Bits);
    }

    constexpr angle operator-() const noexcept {
        return {nullptr, -data};
    }

    constexpr angle& operator+=(angle rhs) noexcept {
        data += rhs.data;
        return *this;
    }

    int data;
};

namespace {

constexpr auto operator==(angle lhs, angle rhs) noexcept {
    return lhs.data == rhs.data;
}

template <std::integral T>
constexpr auto operator==(angle lhs, T rhs) noexcept {
    return lhs.data == rhs;
}

constexpr auto operator<=>(angle lhs, angle rhs) noexcept {
    return lhs.data <=> rhs.data;
}

constexpr auto operator-(angle lhs, angle rhs) noexcept -> angle {
    return {nullptr, lhs.data - rhs.data};
}

constexpr auto operator+(angle lhs, angle rhs) noexcept -> angle {
    return {nullptr, lhs.data + rhs.data};
}

}
