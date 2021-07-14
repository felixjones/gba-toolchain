# gba-toolchain

CMake based toolchain for GBA homebrew development.

# Getting Started

Tutorials for getting started can be found [on the project Wiki](https://github.com/felixjones/gba-toolchain/wiki).

## CMake functions

A list of gba-toolchain CMake functions can be found [on the project Wiki](https://github.com/felixjones/gba-toolchain/wiki/CMake-Functions-(2.0.0)).

## Samples

Samples can be found in the `samples/` directory. They can be built from within their directories with: `cmake -DCMAKE_TOOLCHAIN_FILE=../../arm-gba-toolchain.cmake . && make`

# Requirements

## CMake environment

All the setup is performed via CMake. This allows any CMake compatible IDE to work out of the box.

Add the toolchain to your CMake project with `-DCMAKE_TOOLCHAIN_FILE=path/to/arm-gba-toolchain.cmake`, this defines `GBA_TOOLCHAIN` which can be tested for on your cross-platform CMake project.

## Internet connection (initial setup)

The `arm-gba-toolchain.cmake` script will attempt to download the following dependencies

|Dependency|Source|Destination||
|---|---|---|---|
|GNU Arm Embedded Toolchain|[ARM developer website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)|   gba-toolchain/arm-none-eabi|GNU toolchain used for compiling GBA projects|
|gbafix*|[gba-tools GitHub master](https://raw.githubusercontent.com/devkitPro/gba-tools/master/src/gbafix.c)|gba-toolchain/tools/gbafix|Fixes GBA ROM headers for compatibility with real hardware|
|tonclib|[libtonc GitHub master](https://github.com/devkitPro/libtonc)|gba-toolchain/lib/tonc|C library for GBA development|
|gba-plusplus|[gba-plusplus GitHub master](https://github.com/felixjones/gba-plusplus)|gba-toolchain/lib/gba-plusplus|C++ library for GBA development|
|maxmod|[maxmod GitHub master](https://github.com/devkitPro/maxmod)|gba-toolchain/lib/maxmod|C library for GBA sound playback|
|gbfs*|[gbfs developer website](http://www.pineight.com/gba/#gbfs)|gba-toolchain/lib/gbfs, gba-toolchain/tools/gfbs|File system tools and library for GBA resource management
|agbabi|[agbabi GitHub master](https://github.com/felixjones/agbabi)|gba-toolchain/lib/agbabi|Optimized implementations for common GBA functions|
|posprintf|[posprintf developer website](http://danposluns.com/danposluns/gbadev/posprintf/index.html)|gba-toolchain/lib/posprintf|Partial implementation of sprintf for the GBA|
|nedclib*|[nedclib GitHub master](https://github.com/Lymia/nedclib)|gba-toolchain/tools/nedclib|e-reader dot code generator|

\* requires a host compiler, such as Visual Studio's CL.exe, GCC or Clang.

# Example CMake

This example CMake has the source file `main.c` and builds `gba_example.elf` and `example_out.gba`.

```cmake
cmake_minimum_required(VERSION 3.0)
project(my_gba_project)

add_executable(gba_example main.c)
set_target_properties(gba_example PROPERTIES SUFFIX ".elf") # Building gba_example.elf

if(GBA_TOOLCHAIN)
    # setup IWRAM/EWRAM instruction sets and set default ROM instruction set to thumb
    gba_target_sources_instruction_set(gba_example thumb)

    # link with rom runtime (alternative is multiboot)
    gba_target_link_runtime(gba_example rom)

    # add objcopy command (elf to gba)
    gba_target_object_copy(gba_example "gba_example.elf" "example_out.gba")

    # gbafix settings (used with gba_target_fix)
    set(ROM_TITLE "Example")
    set(ROM_GAME_CODE "CEGE")
    set(ROM_MAKER_CODE "EG")
    set(ROM_VERSION 100)

    # add gbafix command (gba ROM header information)
    gba_target_fix(gba_example "example_out.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
else()
    message(FATAL_ERROR "gba-toolchain not set (did you remember CMAKE_TOOLCHAIN_FILE?)")
endif()
```

# Enable Clang

The CMake option `-DUSE_CLANG=ON` will enable searching for and activating Clang compilers.

# Enable urls.txt update

The CMake option `-DUPDATE_URLS_TXT=ON` will enable downloading and updating urls.txt from [github.com/felixjones/gba-toolchain/blob/master/urls.txt](https://github.com/felixjones/gba-toolchain/blob/master/urls.txt)
