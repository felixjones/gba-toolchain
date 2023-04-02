#pragma once

#include <algorithm>
#include <array>
#include <cstddef>

namespace lut {

    template <std::size_t N, class Generator>
    constexpr auto make(Generator g) -> std::array<decltype(g(std::size_t{})), N> {
        auto result = std::array<decltype(g(std::size_t{})), N>{};
        for (std::size_t ii = 0; ii < N; ++ii) {
            result[ii] = g(ii);
        }
        return result;
    }

}
