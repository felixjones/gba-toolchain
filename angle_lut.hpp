#pragma once

#include <array>

#include "fixed.hpp"

namespace angle_lut {

    template <std::size_t N, class Generator>
    constexpr auto make(Generator g) noexcept {
        static_assert((N & (N - 1)) == 0, "N must be a power of 2");

        using item_type = decltype(g(std::size_t{}));
        using array_type = std::array<item_type, N>;

        auto result = array_type{};
        for (std::size_t ii = 0; ii < N; ++ii) {
            result[ii] = g(ii);
        }

        struct angle_to : public array_type {
            constexpr explicit angle_to(const array_type& data) noexcept : array_type{data} {}

            constexpr auto operator[](angle a) const noexcept -> array_type::const_reference {
                return this->at(static_cast<array_type::size_type>(a.to_int<__builtin_ctz(N) + 1>()));
            }
        };

        return angle_to{result};
    }

} // namespace angle_lut
