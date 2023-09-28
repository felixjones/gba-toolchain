# gba-toolchain

# Requirements

* [CMake](https://cmake.org/) (3.18 minimum)
* Arm compiler toolchain ([Arm GNU Toolchain](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads), [devkitPro](https://devkitpro.org/))

# Basic usage

gba-toolchain provides a CMake toolchain file "`cmake/gba.toolchain.cmake`" that sets up compilers & tools for GBA development.

For more information on CMake toolchains see: [cmake-toolchains cross-compiling](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling)

## Command line

CMake toolchains can be used with CMake on the command line as such:

```shell
cmake -S . -B build --toolchain=/path/to/cmake/gba.toolchain.cmake
```

Or for CMake versions prior to `3.21`:

```shell
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=/path/to/cmake/gba.toolchain.cmake
```

## CMake presets file

For more information on CMake presets files see: [cmake-presets configure-preset](https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html)

Objects of `configurePresets` has the member `toolchainFile`:

```json
{
  "version": 3,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 21,
    "patch": 0
  },
  "configurePresets": [
    {
      "name": "gba-toolchain",
      "generator": "Unix Makefiles",
      "toolchainFile": "/path/to/cmake/gba.toolchain.cmake"
    }
  ]
}
```

# Example CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.18)
project(my_project LANGUAGES C)

add_executable(my_executable main.c)

# gba-toolchain sets `CMAKE_SYSTEM_NAME` to `AdvancedGameBoy`
if(CMAKE_SYSTEM_NAME STREQUAL AdvancedGameBoy)
    find_package(librom REQUIRED) # ROM runtime
    find_package(libseven REQUIRED) # C development library
    find_package(agbabi REQUIRED) # Optimized library functions

    target_compile_options(my_executable PRIVATE -mthumb -fconserve-stack -fomit-frame-pointer)
    target_link_libraries(my_executable PRIVATE librom libseven agbabi)
    
    # ROM header info
    set_target_properties(my_executable PROPERTIES
        ROM_TITLE "My Game"
        ROM_ID AABE
        ROM_MAKER CD
        ROM_VERSION 1
    )

    # install to .gba
    install_rom(my_executable)
endif()
```

# CMake modules

CMake modules are made available with the `find_package` function.

For more information on CMake `find_package` see: [cmake-commands find_package](https://cmake.org/cmake/help/latest/command/find_package.html)

| Package       | Module                  | Description                                                                                                                    | Additional CMake functions                                       |
|---------------|-------------------------|--------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------|
| librom        | FindLibrom.cmake        | ROM runtime library for standard .gba ROMs                                                                                     |                                                                  |
| libmultiboot  | FindLibmultiboot.cmake  | Multiboot runtime library for executables transferred via GBA MultiBoot                                                        |                                                                  |
| gba-hpp       | FindGba-Hpp.cmake       | C++20 GBA development library ([more info](https://github.com/felixjones/gba-hpp))                                             |                                                                  |
| libseven      | FindLibseven.cmake      | Modern C GBA development library from sdk-seven ([more info](https://github.com/LunarLambda/sdk-seven))                        |                                                                  |
| libgba        | FindLibgba.cmake        | C GBA development library from devkitPro ([more info](https://github.com/devkitPro/libgba))                                    |                                                                  |
| tonclib       | FindTonclib.cmake       | Classic C GBA development library from Coranac ([more info](https://www.coranac.com/man/tonclib/main.htm))                     |                                                                  |
| gbfs          | FindGbfs.cmake          | Archive format for the GBA ([more info](https://pineight.com/gba/#gbfs))                                                       | `add_gbfs_archive`                                               |
| maxmod        | FindMaxmod.cmake        | GBA music and sound solution ([more info](https://maxmod.devkitpro.org/))                                                      | `add_maxmod_soundbank`                                           |
| superfamiconv | FindSuperfamiconv.cmake | Tile graphics converter ([more info](https://github.com/Optiroc/SuperFamiconv))                                                | `add_superfamiconv_graphics`                                     |
| agbabi        | FindAgbabi.cmake        | Library functions optimized for the GBA ([more info](https://github.com/felixjones/agbabi))                                    |                                                                  |
| posprintf     | FindPosprintf.cmake     | Partial implementation of `sprintf` optimized for the GBA ([more info](http://www.danposluns.com/gbadev/posprintf/index.html)) |                                                                  |
| grit          | FindGrit.cmake          | Bitmap and Tile graphics converter ([more info](https://www.coranac.com/man/grit/html/grit.htm))                               | `add_grit_bitmap`<br />`add_grit_sprite`<br />`add_grit_tilemap` |

**Important**: Some modules may have external dependencies that may require tools to be compiled with a host compiler.
