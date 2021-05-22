# gba-toolchain

CMake based toolchain for GBA homebrew development.

# Requirements

## CMake environment

All the setup is performed via CMake. This allows any CMake compatible IDE to work out of the box.

Add the toolchain to your CMake project with `-DCMAKE_TOOLCHAIN_FILE=path/to/arm-gba-toolchain.cmake`, this defines `GBA_TOOLCHAIN` which can be tested for on your cross-platform CMake project.

## Internet connection (initial setup)

The `arm-gba-toolchain.cmake` script will attempt to download the following dependencies

|Dependency|Source|Destination||
|---|---|---|---|
|GNU Arm Embedded Toolchain|[ARM developer website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)|   gba-toolchain/arm-none-eabi|GNU toolchain used for compiling GBA projects|
|gbafix*|[gba-tools GitHub master](https://raw.githubusercontent.com/devkitPro/gba-tools/master/src/gbafix.c)|gba-toolchain/tools|Fixes GBA ROM headers for compatibility with real hardware|
|tonclib|[libtonc GitHub master](https://github.com/devkitPro/libtonc)|gba-toolchain/lib/tonc|C library for GBA development|
|gba-plusplus|[gba-plusplus GitHub master](https://github.com/felixjones/gba-plusplus)|gba-toolchain/lib/gba-plusplus|C++ library for GBA development|
|maxmod|[maxmod GitHub master](https://github.com/devkitPro/maxmod)|gba-toolchain/lib/maxmod|C library for GBA sound playback|
|gbfs*|[gbfs developer website](http://www.pineight.com/gba/#gbfs)|gba-toolchain/lib/gbfs|File system tools and library for GBA resource management|
|agbabi|[agbabi GitHub master](https://github.com/felixjones/agbabi)|gba-toolchain/lib/agbabi|Optimized implementations for common GBA functions|
|posprintf|[posprintf developer website](http://danposluns.com/danposluns/gbadev/posprintf/index.html)|gba-toolchain/lib/posprintf|Partial implementation of sprintf for the GBA|

\* requires a host compiler, such as Visual Studio's CL.exe, GCC or Clang.

# Example CMake

This example CMake has the source file `main.c` and builds `gba_example.elf` and `example_out.gba`.

```cmake
cmake_minimum_required(VERSION 3.0)
project(my_gba_project)

add_executable(gba_example main.c)
set_target_properties(gba_example PROPERTIES SUFFIX ".elf") # Building gba_example.elf

# activate & link GBA optimized ABI library
gba_target_link_agb_abi(gba_example)

# activate & link tonc dependency
gba_target_link_tonc(gba_example)

# activate & link maxmod dependency
gba_target_link_maxmod(gba_example)

# setup IWRAM/EWRAM instruction sets and set default ROM instruction set to thumb
gba_target_sources_instruction_set(gba_example thumb)

# link with rom runtime (alternative is multiboot)
gba_target_link_runtime(gba_example rom)

# add objcopy command (elf to gba)
gba_target_object_copy(gba_example "gba_example.elf" "example_out.gba")

# gbafix
if(EXISTS ${GBA_TOOLCHAIN_GBAFIX})
    # gbafix settings (used with gba_target_fix)
    set(ROM_TITLE "Example")
    set(ROM_GAME_CODE "CEGE")
    set(ROM_MAKER_CODE "EG")
    set(ROM_VERSION 100)

    # add gbafix command (gba ROM header information)
    gba_target_fix(gba_example "example_out.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
endif()
```

# Enable Clang

The CMake option `-DUSE_CLANG=ON` will enable searching for and activating Clang compilers.

# Enable urls.txt update

The CMake option `-DUPDATE_URLS_TXT=ON` will enable downloading and updating urls.txt from [github.com/felixjones/gba-toolchain/blob/master/urls.txt](https://github.com/felixjones/gba-toolchain/blob/master/urls.txt)
