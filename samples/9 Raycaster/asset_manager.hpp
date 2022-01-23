#ifndef ASSET_MANAGER_HPP
#define ASSET_MANAGER_HPP

#include <cstdint>

namespace assets {

    constexpr auto map_size = 24;
    using map_type = std::uint8_t[map_size];

    static constexpr auto texture_size = 64;
    using row_type = std::uint8_t[texture_size];
    using texture_type = row_type[texture_size];

    using texture_pair_type = texture_type[2]; // Lit + Unlit

    void load();

    extern const map_type* world_map;
    extern const texture_pair_type* texture_array;

} // assets

#endif // define ASSET_MANAGER_HPP
