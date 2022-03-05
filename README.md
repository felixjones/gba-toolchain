# gba-toolchain

### Please see the [Sample Projects](https://github.com/felixjones/gba-toolchain/tree/3.0/samples) for example GBA projects.

## Requirements

* [CMake](https://cmake.org/) (3.18 minimum)
* Host compiler (optional for compiling additional tools)

## Basic Usage

gba-toolchain uses [CMake toolchain files](https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html#cross-compiling) to download and compile dependencies and set up compilers for cross-compiling.

The toolchain file (`arm-gba-toolchain.cmake`) is activated with the command line parameter `--toolchain /path/to/arm-gba-toolchain.cmake` when invoking CMake.

gba-toolchain will attempt to locate an installation of the [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm).
If the GNU Arm Embedded Toolchain cannot be located, it will be downloaded to the host `local` directory (`%LocalAppData%` on Windows, `~/` on Linux, `/usr/local/share` on macOS).

## GBA Libraries

If a library is required by CMake, but is missing, it will be downloaded into the `gba-toolchain/lib` directory.

### libseven

[libseven](https://github.com/LunarLambda/libseven) is a modern GBA C development library that also provides commonly needed utility functions.

### Tonclib/libtonc

[libtonc](https://github.com/devkitPro/libtonc) is the classic GBA C development library. Includes a text rendering engine, [Tonc's Text Engine](https://www.coranac.com/tonc/text/tte.htm).

### agbabi

[agbabi](https://github.com/felixjones/agbabi) ARM embedded ABI functions optimized for GBA. Also provides additional, low-level GBA utility functions.

Simply linking with agbabi will activate the optimised aeabi functions.

### GBFS

[gbfs](https://pineight.com/gba/#gbfs) provides an asset file system for GBA. Includes several tools for managing these.

### posprintf

[posprintf](http://www.danposluns.com/gbadev/posprintf/instructions.html) is a partial implementation of sprintf optimized for GBA.

### Maxmod

[Maxmod](https://maxmod.devkitpro.org/) is a complete music and sound solution for the GBA.

## Runtime libraries

A compiler runtime-library (`crt0.s`) and linker script (`lib/ldscripts`) is required for compiling a GBA binary.

gba-toolchain provides some optional runtime libraries for convenience.

All runtimes support GNU destructors, finalizers, and C++ global static destructors.
These come with a small EWRAM cost, but can be disabled with the definition `__NO_FINI__` (ideal for programs that never return or exit and thus do not need these features).

The linker scripts for these runtimes will reserve a minimum of 512 bytes for stack space.

### librom

Runtime library for regular GBA ROMs.

The definition `__ROM_START_PADDING__=bytes-to-pad` can be used to insert padding after the ROM header, useful for inserting save type strings.

### libmultiboot

Runtime library for Multiboot binaries. Multiboot binaries are usually transferred via GBA link cable from a host device to one or more connected GBA clients.

If launched as a regular ROM (from emulator, or similar) libmultiboot will copy ROM contents to EWRAM before executing.
The extra code for ROM copying can be removed by adding the `__NO_ROM_COPY__` definition.

### libereader

Runtime library for e-Reader binaries.

e-Reader binaries have no header, however 4 bytes at `0x2000008` are clobbered by the e-Reader device ROM.

An e-Reader binary can ´exit´ back to the e-Reader ROM.

## Tools

**Tools require a host compiler** for building.

Alternatively, paths to precompiled tool binaries can be defined with CMake variables.

If a tool is required by CMake, but is missing, it will be downloaded and compiled.

### gbafix

A valid header is required for running ROMs on actual hardware.

[gbafix](https://github.com/devkitPro/gba-tools/blob/master/src/gbafix.c) is used to "fix" a GBA binary (AKA: adds a header) so it can execute on hardware.

### nedcmake

[Nedcmake](https://github.com/Lymia/nedclib) is used to convert an [e-Reader](https://en.wikipedia.org/wiki/Nintendo_e-Reader) binary into dot-code images (in .bmp format).

### gbfs

[gbfs](https://pineight.com/gba/#gbfs) provides a number of tools for managing GBFS asset file archives.

#### gbfs

The titular gbfs program bundles input sources into a GBFS archive.

#### bin2s

Converts a given binary file to an ASM source file. Useful for compiling GBFS archives directly into a ROM.

#### padbin

Pads a given binary to the next nearest multiple of a given number.
GBFS searches on 256 byte boundaries, making this useful for aligning a ROM for appending a GBFS archive onto.

#### mmutil

Compiles audio files into a Maxmod sample binary. Can also output an associated header file, or a GBA ROM.

## CMake Options

### -DARM_GNU_TOOLCHAIN=/path/to/arm-gnu-toolchain/root/directory/

Use an existing installation of the GNU Arm Embedded Toolchain.

This can also be configured via the environment variable `ARM_GNU_TOOLCHAIN`.

### -DUSE_CLANG=ON

Changes the compiler from ARM GNU GCC to the host's Clang compiler. This requires [Clang](https://clang.llvm.org/) to be installed.

The GNU Arm Embedded Toolchain is still required for GCC linking, compiling assembly, objcopy, and for the C/C++ standard libraries.

### -DUSE_DEVKITARM=ON

Changes the compiler from GNU Arm Embedded Toolchain to an installation of devkitARM located at the `DEVKITARM` environment variable.

This avoids downloading GNU Arm Embedded Toolchain and uses devkitARM's provided tools when available (can avoid downloading and compiling host tools). 

### -DDEPENDENCIES_URL=https://some.url.to/a/place/with/file.ini

Overrides the initial URL used to download `dependecies.ini`.

Any existing `dependecies.ini` needs to be deleted from the gba-toolchain directory for this variable to take effect.

### -DGBAFIX=/path/to/binary

Use an existing installation of [gbafix](https://github.com/devkitPro/gba-tools/blob/master/src/gbafix.c).

This can also be configured via the environment variable `GBAFIX`.

### -DNEDCMAKE=/path/to/binary

Use an existing installation of [nedcmake](https://github.com/Lymia/nedclib).

This can also be configured via the environment variable `NEDCMAKE`.

### -DGBFS=/path/to/binary

Use an existing installation of [gbfs](https://pineight.com/gba/#gbfs).

This can also be configured via the environment variable `GBFS`.

### -DBIN2S=/path/to/binary

Use an existing installation of bin2s (part of [gbfs](https://pineight.com/gba/#gbfs)).

This can also be configured via the environment variable `BIN2S`.

### -DPADBIN=/path/to/binary

Use an existing installation of padbin (part of [gbfs](https://pineight.com/gba/#gbfs)).

This can also be configured via the environment variable `PADBIN`.

### -DMMUTIL=/path/to/binary

Use an existing installation of [mmutil](https://github.com/devkitPro/mmutil).

This can also be configured via the environment variable `MMUTIL`.
