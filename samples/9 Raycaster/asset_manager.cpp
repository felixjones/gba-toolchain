/*
===============================================================================

 Sample GBA 3D ray-caster based on https://lodev.org/cgtutor/raycasting.html

 Copyright (C) 2021-2022 gba-toolchain contributors
 For conditions of distribution and use, see copyright notice in LICENSE.md

===============================================================================
*/

#include "asset_manager.hpp"

#include <seven/prelude.h>
#include <gbfs.h>
#include <agbabi.h>

#ifndef ASSETS_GBFS
extern const GBFS_FILE assets_gbfs[];
#else
#include <seven/util/log.h>
#include <seven/svc/system.h>

extern const char __rom_end[];
#endif

const assets::map_type* assets::world_map;
const assets::texture_pair_type* assets::texture_array;

void assets::load() {
#ifdef ASSETS_GBFS
    const GBFS_FILE* const assets_gbfs = find_first_gbfs_file(__rom_end);
    if (!assets_gbfs) {
        logOutput(LOG_FATAL, "Could not find assets_gbfs (forgot to concat?)");
        svcHalt();
        __builtin_unreachable();
    }
#endif

    u32 palSize;
    auto* palBinary = gbfs_get_obj(assets_gbfs, "wolftextures.pal", &palSize);
    __agbabi_memcpy2(MEM_PALETTE, palBinary, palSize);

    u32 mapSize;
    world_map = reinterpret_cast<const map_type*>(gbfs_get_obj(assets_gbfs, "map.bin", &mapSize));

    u32 texSize;
    texture_array = reinterpret_cast<const texture_pair_type*>(gbfs_get_obj(assets_gbfs, "wolftextures.bin", &texSize));
}
