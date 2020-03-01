# gba-toolchain

CMake based toolchain for GBA homebrew development.

# Requirements

## CMake environment

All the setup is performed via CMake. This allows a CMake compatible IDE (such as [Visual Studio](https://docs.microsoft.com/en-us/cpp/build/cmake-projects-in-visual-studio) on Windows) to work out of the box.

## Internet connection (initial setup)

The `arm-gba-toolchain.cmake` script will attempt to download the following dependencies

|Dependency|Source|Destination|Used for|
|---|---|---|---|
|GNU Arm Embedded Toolchain|[ARM developer website](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)|   gba-toolchain/arm-none-eabi|GNU toolchain used for compiling GBA projects|
|gbafix (optional)|[devkitPro GitHub master](https://raw.githubusercontent.com/devkitPro/gba-tools/master/src/gbafix.c)|gba-toolchain/tools|Fixing GBA ROM headers for compatibility with real hardware|
|gbaplusplus (optional)|[gbaplusplus GitHub master](https://github.com/felixjones/gbaplusplus)|gba-toolchain/lib/gbaplusplus|C++ library for modern GBA development|

## Host GCC (optional)

Used to compile gbafix. ROMs can still be used with emulators without gbafix or gbafix can be manually used later or manually added to the `tools/gbafix` directory.

## [LLVM](https://llvm.org/) (optional)

If LLVM is installed on the host then gba-toolchain will switch to using Clang/Clang++ for compiling C/C++ code.
