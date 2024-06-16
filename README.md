# gba-toolchain

# Requirements

* [CMake](https://cmake.org/) (3.25 minimum)
* Arm compiler toolchain ([Arm GNU Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads), [devkitPro](https://devkitpro.org/))

# Basic usage

gba-toolchain provides a CMake toolchain file "`cmake/gba.toolchain.cmake`" that sets up compilers & tools for GBA development.

For more information on CMake toolchains see: [cmake-toolchains cross-compiling](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling)

## Command line

CMake toolchains can be used with CMake on the command line as such:

```shell
cmake -S . -B build/ --toolchain=/path/to/cmake/gba.toolchain.cmake
```

## CMake presets file

For more information on CMake presets files see: [cmake-presets configure-preset](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)

Objects of `configurePresets` has the member `toolchainFile`:

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 25,
    "patch": 1
  },
  "configurePresets": [
    {
      "name": "gba-toolchain",
      "generator": "Unix Makefiles",
      "toolchainFile": "/path/to/cmake/gba.toolchain.cmake",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": {
          "type": "STRING",
          "value": "Debug"
        }
      }
    }
  ]
}
```

# Example CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.25.1)
project(my_project LANGUAGES C VERSION 1.0.0)

find_package(librom REQUIRED)
find_package(tonclib REQUIRED)
find_package(grit REQUIRED)

add_executable(my_executable
        main.c
)

# ROM header info
set_target_properties(my_executable PROPERTIES
        ROM_TITLE "my game"
        ROM_VERSION 1
)

# Sprite graphics
add_grit_library(sprite
        GRAPHICS_BIT_DEPTH 4
        AREA_RIGHT 64
        graphics/metr.png
)

# Map graphics
add_grit_library(map
        GRAPHICS_BIT_DEPTH 4
        MAP_LAYOUT REGULAR_SBB
        graphics/brin.png
)

target_link_libraries(my_executable PRIVATE
        librom tonclib
        sprite map
)

# Install to .gba
install_rom(my_executable)
```

# Builtin CMake functions

`add_asset_library(<target> [PREFIX <symbol-prefix>] [SUFFIX_START <start-symbol-suffix>] [SUFFIX_END <end-symbol-suffix>] [SUFFIX_SIZE <size-symbol-suffix>] [WORKING_DIRECTORY <working-directory-path>] <file-path>...)`

Compiles assets into a binary object file for linking.

Example:
```cmake
add_asset_library(my_assets
        hello.txt
        image.bin
        palette.pal
)
target_link_libraries(my_executable PRIVATE my_assets)
# hello_txt, image_bin, palette_pal symbols now available via `my_assets.h`
```

# CMake modules

CMake modules are made available with the `find_package` function.

For more information on CMake `find_package` see: [cmake-commands find_package](https://cmake.org/cmake/help/latest/command/find_package.html)

## agbabi

Library functions optimized for the GBA ([more info](https://github.com/felixjones/agbabi))

## Butano

Butano engine ([more info](https://github.com/GValiente/butano))

`add_butano_library(<target> [GRAPHICS <file-path>...] [AUDIO <file-path>...] [DMG_AUDIO <file-path>...])`

## gba-hpp

C++20 GBA development library ([more info](https://github.com/felixjones/gba-hpp))

## gbfs

Archive format for the GBA ([more info](https://pineight.com/gba/#gbfs))

`add_gbfs_library(<target> <file-path>...)`

## gbt-player

Game Boy music player library and converter kit ([more info](https://github.com/AntonioND/gbt-player))

`add_s3msplit_command(<input-s3m> <PSG output-psg> <DMA output-dma>)`

`add_gbt_library(<target> <file-path>...)`

## grit

Bitmap and Tile graphics converter ([more info](https://www.coranac.com/man/grit/html/grit.htm))

```cmake
add_grit_library(<target> [PALETTE_SHARED] [GRAPHICS_SHARED] [FLAGS <flags-string>] [FLAGS_FILE <flags-path>] [TILESET_FILE <tileset-path>]
    [PALETTE|NO_PALETTE]
    [PALETTE_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
    [PALETTE_RANGE_START <integer>]
    [PALETTE_RANGE_END <integer>]
    [PALETTE_COUNT <integer>]
    [PALETTE_TRANSPARENT_INDEX <integer>]
    [GRAPHICS|NO_GRAPHICS]
    [GRAPHICS_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
    [GRAPHICS_PIXEL_OFFSET <integer>]
    [GRAPHICS_FORMAT <BITMAP|TILE>]
    [GRAPHICS_BIT_DEPTH <integer>]
    [GRAPHICS_TRANSPARENT_COLOR <hex-code>]
    [AREA_LEFT <integer>]
    [AREA_RIGHT <integer>]
    [AREA_WIDTH <integer>]
    [AREA_TOP <integer>]
    [AREA_BOTTOM <integer>]
    [AREA_HEIGHT <integer>]
    [MAP|NO_MAP]
    [MAP_COMPRESSION <OFF|LZ77|HUFF|RLE|FAKE>]
    [<MAP_TILE_REDUCTION <TILES|PALETTES|FLIPPED>...>|MAP_NO_TILE_REDUCTION]
    [MAP_LAYOUT <REGULAR_FLAT|REGULAR_SBB|AFFINE>]
    [METATILE_HEIGHT <integer>]
    [METATILE_WIDTH <integer>]
    [METATILE_REDUCTION]
    <file-path>...
)
```

## libgba

C GBA development library from devkitPro ([more info](https://github.com/devkitPro/libgba))

## libmultiboot

Multiboot runtime library for executables transferred via GBA MultiBoot

## librom

ROM runtime library for standard .gba ROMs.

`install_rom(<target> [CONCAT [ALIGN <byte-alignment>] <artifact>...])`

## libsavgba

A library to access various backup media in GBA cartridges ([more info](https://github.com/laqieer/libsavgba))

## maxmod

GBA music and sound solution ([more info](https://maxmod.devkitpro.org/))

`add_maxmod_library(<target> <file-path>...)`

## posprintf

Partial implementation of `sprintf` optimized for the GBA ([more info](http://www.danposluns.com/gbadev/posprintf/index.html))

## sdk-seven

Modern GBA SDK ([more info](https://github.com/sdk-seven))

`add_gbafix_target(<target> <executable-target>)`

### Components

#### runtime

Provides `sdk-seven::minrt` and `sdk-seven::minrt_mb` runtime libraries.

#### libseven

Provides `sdk-seven::libseven` C development library.

#### libutil

Provides `sdk-seven::libutil` support library.

## superfamiconv

Tile graphics converter ([more info](https://github.com/Optiroc/SuperFamiconv))

```cmake
add_superfamiconv_library(<target> [PALETTE] [TILES] [MAP]
    [PALETTE_SPRITE_MODE]
    [PALETTE_COUNT <integer>]
    [PALETTE_COLORS <integer>]
    [PALETTE_COLOR_ZERO <hex-code>]
    [TILES_NO_DISCARD]
    [TILES_NO_FLIP]
    [TILES_SPRITE_MODE]
    [TILES_BPP <integer>]
    [TILES_MAX <integer>]
    [MAP_NO_FLIP]
    [MAP_COLUMN_ORDER]
    [MAP_BPP <integer>]
    [MAP_TILE_BASE <integer>]
    [MAP_PALETTE_BASE <integer>]
    [MAP_WIDTH <integer>]
    [MAP_HEIGHT <integer>]
    [MAP_SPLIT_WIDTH <tiles>]
    [MAP_SPLIT_HEIGHT <tiles>]
    <file-path>...
)
```

## tonclib

Classic C GBA development library from Coranac ([more info](https://www.coranac.com/man/tonclib/main.htm))

## xilefianlib

Some of my (Xilefian's) utility libraries ([more info](https://github.com/felixjones/xilefianlib))
