cmake_minimum_required(VERSION 3.8)

project("Game Boy Advance")

set(PlatformTarget			"arm-none-eabi")
set(PlatformCore			"arm7tdmi")
set(PlatformArchitecture	"armv4t")
set(PlatformInstructionSet	"thumb")

set(devkitARM $ENV{DEVKITARM})
if(NOT devkitARM)
	message(FATAL_ERROR "Failed to locate devkitARM")
endif()

#====================
# GCC
#====================

set(GCCBin "${devkitARM}/bin/${PlatformTarget}-")

find_program(HasGCC "${GCCBin}gcc" "${GCCBin}g++")
if(HasGCC)
	set(CompilerC "${GCCBin}gcc")
	set(CompilerCXX "${GCCBin}g++")
	set(CompilerFlags "-Wno-packed-bitfield-compat")
else()
	message(STATUS "Could not locate GCC")
endif()

set(GCCAs "${GCCBin}as")
set(GCCAr "${GCCBin}gcc-ar")
set(GCCObjcopy "${GCCBin}objcopy")
set(GCCStrip "${GCCBin}strip")
set(GCCNm "${GCCBin}gcc-nm")
set(GCCRanlib "${GCCBin}gcc-ranlib")

#====================
# Clang
#====================

find_program(HasClang "clang" "clang++")
if(HasClang)
	set(CompilerC "clang")
	set(CompilerCXX "clang++")
	set(CompilerFlags "--target=${PlatformTarget}")
	message(STATUS "Clang activated")
endif()

#====================
# Language
#====================

set(SharedFlags "${CompilerFlags} -mcpu=${PlatformCore} -mtune=${PlatformCore} -march=${PlatformArchitecture} -Wall -pedantic -pedantic-errors -fomit-frame-pointer -ffast-math")

#====================
# C
#====================

set(CFlags "${SharedFlags}")

#====================
# C++
#====================

set(CXXFlags "${SharedFlags} -fno-rtti -fno-exceptions")
set(CMAKE_CXX_STANDARD 20)

#====================
# Main Code
#====================

file(GLOB MainSources
	"source/*.c"
	"source/*.cpp"
)
list(FILTER MainSources EXCLUDE REGEX "((\.iwram)|(\.arm)|(\.thumb))(\.c[a-z]*)")

if(MainSources)
	add_library(MainCode OBJECT ${MainSources})
	target_compile_options(MainCode PRIVATE "-m${PlatformInstructionSet}")
endif()

#====================
# thumb Code
#====================

file(GLOB thumbSources
	"source/*.thumb.c"
	"source/*.thumb.cpp"
)

if(thumbSources)
	add_library(thumbCode OBJECT ${thumbSources})
	target_compile_options(thumbCode PRIVATE "-mthumb")
endif()

#====================
# ARM Code
#====================

file(GLOB armSources
	"source/*.arm.c"
	"source/*.arm.cpp"
)

if(armSources)
	add_library(ARMCode OBJECT ${armSources})
	target_compile_options(ARMCode PRIVATE "-marm")
endif()

#====================
# IWRAM Code
#====================

file(GLOB IWRAMSources
	"source/*.iwram.c"
	"source/*.iwram.cpp"
)

if(IWRAMSources)
	add_library(IWRAMCode OBJECT ${IWRAMSources})
	target_compile_options(IWRAMCode PRIVATE "-marm" "-mlong-calls")
endif()

#====================
# CMAKE
#====================

set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

set(CMAKE_C_COMPILER ${CompilerC})
set(CMAKE_C_FLAGS ${CFlags})

set(CMAKE_CXX_COMPILER ${CompilerCXX})
set(CMAKE_CXX_FLAGS ${CXXFlags})

set(CMAKE_OBJCOPY ${GCCObjcopy})
set(CMAKE_STRIP ${GCCStrip})
set(CMAKE_NM ${GCCNm})
set(CMAKE_RANLIB ${GCCRanlib})

#====================
# ELF
#====================

add_executable(rom.elf)

if(MainSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:MainCode>)
endif()

if(thumbSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:thumbCode>)
endif()

if(ARMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:ARMCode>)
endif()

if(IWRAMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
endif()

set(CMAKE_C_COMPILER "${GCCBin}gcc")
set(CMAKE_C_FLAGS "-specs=gba.specs")

set(CMAKE_CXX_COMPILER "${GCCBin}g++")
set(CMAKE_CXX_FLAGS "-specs=gba.specs")
