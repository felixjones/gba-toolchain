cmake_minimum_required(VERSION 3.8)

project("GameBoyAdvance" ASM C CXX)
set(CMAKE_SYSTEM_NAME "GBA")

set(GameID "GAME")

set(PlatformTarget			"arm-none-eabi")
set(PlatformCore			"arm7tdmi")
set(PlatformArchitecture	"armv4t")
set(PlatformInstructionSet	"thumb")

if(NOT CMAKE_BUILD_TYPE) 
    set(CMAKE_BUILD_TYPE Release)
endif(NOT CMAKE_BUILD_TYPE)

#====================
# ARM GNU Toolchain
#====================

set(ARM_GNU_PATH "${PROJECT_SOURCE_DIR}/arm-gnu-toolchain")
set(ARM_GNU_URL_BASE "https://developer.arm.com/-/media/Files/downloads/gnu-rm")

if(NOT EXISTS "${ARM_GNU_PATH}/arm-none-eabi")
	if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
		set(ARM_GNU_URL "${ARM_GNU_URL_BASE}/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-win32.zip")
		set(ARM_GNU_ARCHIVE_PATH "${ARM_GNU_PATH}/gcc-arm-none-eabi.zip")
	elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
		set(ARM_GNU_URL "${ARM_GNU_URL_BASE}/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2")
		set(ARM_GNU_ARCHIVE_PATH "${ARM_GNU_PATH}/gcc-arm-none-eabi.tar.bz2")
	elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
		set(ARM_GNU_URL "${ARM_GNU_URL_BASE}/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-mac.tar.bz2")
		set(ARM_GNU_ARCHIVE_PATH "${ARM_GNU_PATH}/gcc-arm-none-eabi.tar.bz2")
	else()
		message(FATAL_ERROR "Failed to recognise host operating system (${CMAKE_HOST_SYSTEM_NAME})")
	endif()

	message(STATUS "Downloading ARM GNU toolchain from ${ARM_GNU_URL} to ${ARM_GNU_ARCHIVE_PATH}")
    file(DOWNLOAD "${ARM_GNU_URL}" "${ARM_GNU_ARCHIVE_PATH}")

	message(STATUS "Extracting ARM GNU toolchain to ${ARM_GNU_PATH}")
	if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
		execute_process(
			COMMAND powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('${ARM_GNU_ARCHIVE_PATH}', '${ARM_GNU_PATH}/'); }"
		)
	else()
		execute_process(
			COMMAND tar -xvf "${ARM_GNU_ARCHIVE_PATH}" -C "${ARM_GNU_PATH}/"
		)
	endif()
endif()

#====================
# DKP Tools
#====================

set(devkitPro $ENV{DEVKITPRO})
if(NOT DEFINED devkitPro)
	message(STATUS "Failed to locate devkitPro")
endif()

find_program(HasGBAFix "${devkitPro}/tools/bin/gbafix")
if(HasGBAFix)
	set(GBAFixROM ${devkitPro}/tools/bin/gbafix rom.gba -c${GameID})
	set(GBAFixMultiboot ${devkitPro}/tools/bin/gbafix multiboot.gba -c${GameID})
	message(STATUS "gbafix detected")
endif()

#====================
# GCC
#====================

set(GCCBin "${ARM_GNU_PATH}/bin/${PlatformTarget}-")

find_program(HasGCC "${GCCBin}gcc" "${GCCBin}g++")
if(HasGCC)
	set(CompilerASM "${GCCBin}gcc")
	set(CompilerC "${GCCBin}gcc")
	set(CompilerCXX "${GCCBin}g++")
	set(CompilerFlags "-Wno-packed-bitfield-compat")
else()
	message(FATAL_ERROR "Failed to locate GCC")
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
	set(CompilerFlags "--target=arm-arm-none-eabi -mfpu=none -isystem${ARM_GNU_PATH}/arm-none-eabi/include/ -I${ARM_GNU_PATH}/arm-none-eabi/include/c++/9.2.1/ -I${ARM_GNU_PATH}/arm-none-eabi/include/c++/9.2.1/arm-none-eabi/")
	message(STATUS "Clang activated")
endif()

#====================
# Language
#====================

set(ASMFlags "-mcpu=${PlatformCore} -mtune=${PlatformCore} -march=${PlatformArchitecture} -mfloat-abi=soft -Wall -pedantic -pedantic-errors -fomit-frame-pointer -ffast-math")
set(SharedFlags "${CompilerFlags} ${ASMFlags}")
set(CFlags "${SharedFlags}")
set(CXXFlags "${SharedFlags} -fno-rtti -fno-exceptions -std=c++2a")

#====================
# Headers
#====================

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/source")

file(GLOB Headers
	"source/*.h"
	"source/*.hpp"
)

#====================
# Main Code
#====================

file(GLOB MainSources
	"source/*.s"
	"source/*.c"
	"source/*.cpp"
)
list(FILTER MainSources EXCLUDE REGEX "((\.ewram)|(\.iwram)|(\.arm)|(\.thumb))(\.s|\.c|\.cpp)")

if(MainSources)
	add_library(MainCode OBJECT ${Headers} ${MainSources})
	target_compile_options(MainCode PRIVATE "-m${PlatformInstructionSet}")
endif()

#====================
# thumb Code
#====================

file(GLOB thumbSources
	"source/*.thumb.s"
	"source/*.thumb.c"
	"source/*.thumb.cpp"
)

if(thumbSources)
	add_library(thumbCode OBJECT ${Headers} ${thumbSources})
	target_compile_options(thumbCode PRIVATE "-mthumb")
endif()

#====================
# ARM Code
#====================

file(GLOB armSources
	"source/*.arm.s"
	"source/*.arm.c"
	"source/*.arm.cpp"
)

if(armSources)
	add_library(ARMCode OBJECT ${Headers} ${armSources})
	target_compile_options(ARMCode PRIVATE "-marm")
endif()

#====================
# IWRAM Code
#====================

file(GLOB IWRAMSources
	"source/*.iwram.s"
	"source/*.iwram.c"
	"source/*.iwram.cpp"
)

if(IWRAMSources)
	add_library(IWRAMCode OBJECT ${Headers} ${IWRAMSources})
	target_compile_options(IWRAMCode PRIVATE "-marm" "-mlong-calls")
endif()

#====================
# EWRAM Code
#====================

file(GLOB EWRAMSources
	"source/*.ewram.s"
	"source/*.ewram.c"
	"source/*.ewram.cpp"
)

if(EWRAMSources)
	add_library(EWRAMCode OBJECT ${Headers} ${EWRAMSources})
	target_compile_options(EWRAMCode PRIVATE "-mthumb" "-mlong-calls")
endif()

#====================
# Specs
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
	set(CRT0Output "crt0.s.obj")
	set(SyscallsOutput "gba-syscalls.c.obj")
else()
	set(CRT0Output "crt0.o")
	set(SyscallsOutput "gba-syscalls.o")
endif()

#====================
# Specs ROM
#====================

set(CRT0ROMOutputPath "${CMAKE_BINARY_DIR}/CMakeFiles/CRT0ROM.dir/lib/rom/${CRT0Output}")
set(SyscallsROMOutputPath "${CMAKE_BINARY_DIR}/CMakeFiles/CRT0ROM.dir/lib/rom/${SyscallsOutput}")

file(GLOB CRT0ROMSource "${PROJECT_SOURCE_DIR}/lib/rom/*.h" "${PROJECT_SOURCE_DIR}/lib/rom/*.s" "${PROJECT_SOURCE_DIR}/lib/rom/*.c")
add_library(CRT0ROM OBJECT ${CRT0ROMSource})
target_compile_options(CRT0ROM PRIVATE "-mthumb")

message(STATUS "Writing ROM specs")
string(CONCAT SpecsROMContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${PROJECT_SOURCE_DIR}/lib/rom/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0ROMOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsROMOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/rom.specs" ${SpecsROMContents})

#====================
# Specs Multiboot
#====================

set(CRT0MultibootOutputPath "${CMAKE_BINARY_DIR}/CMakeFiles/CRT0Multiboot.dir/lib/multiboot/${CRT0Output}")
set(SyscallsMultibootOutputPath "${CMAKE_BINARY_DIR}/CMakeFiles/CRT0Multiboot.dir/lib/multiboot/${SyscallsOutput}")

file(GLOB CRT0MultibootSource "${PROJECT_SOURCE_DIR}/lib/multiboot/*.h" "${PROJECT_SOURCE_DIR}/lib/multiboot/*.s" "${PROJECT_SOURCE_DIR}/lib/multiboot/*.c")
add_library(CRT0Multiboot OBJECT ${CRT0MultibootSource})
target_compile_options(CRT0Multiboot PRIVATE "-mthumb")

message(STATUS "Writing Multiboot specs")
string(CONCAT SpecsMultibootContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${PROJECT_SOURCE_DIR}/lib/multiboot/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0MultibootOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsMultibootOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_BINARY_DIR}/multiboot.specs" ${SpecsMultibootContents})

#====================
# CMake
#====================

set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

set(CMAKE_ASM_COMPILER ${CompilerASM})
set(CMAKE_ASM_FLAGS ${ASMFlags})

set(CMAKE_C_COMPILER ${CompilerC})
set(CMAKE_C_FLAGS ${CFlags})

set(CMAKE_CXX_COMPILER ${CompilerCXX})
set(CMAKE_CXX_FLAGS ${CXXFlags})

set(CMAKE_OBJCOPY ${GCCObjcopy})
set(CMAKE_STRIP ${GCCStrip})
set(CMAKE_NM ${GCCNm})
set(CMAKE_RANLIB ${GCCRanlib})

set(CMAKE_LINKER "${GCCBin}g++")

set(CMAKE_ASM_LINK_FLAGS "-lc -lstdc++")
set(CMAKE_ASM_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_ASM_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_LINK_FLAGS "-lc -lstdc++")
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_CXX_LINK_FLAGS "-lc -lstdc++")
set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_CXX_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

#====================
# ROM & Multiboot
#====================

add_executable(rom.elf)
add_executable(multiboot.elf)

target_link_libraries(rom.elf PRIVATE -specs=${CMAKE_BINARY_DIR}/rom.specs)
target_link_libraries(multiboot.elf PRIVATE -specs=${CMAKE_BINARY_DIR}/multiboot.specs)

if(MainSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:MainCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:MainCode>)
endif()

if(thumbSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:thumbCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:thumbCode>)
endif()

if(ARMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:ARMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:ARMCode>)
endif()

if(IWRAMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
endif()

if(EWRAMSources)
	target_sources(rom.elf PUBLIC $<TARGET_OBJECTS:EWRAMCode>)
	target_sources(multiboot.elf PUBLIC $<TARGET_OBJECTS:EWRAMCode>)
endif()

#====================
# GBA
#====================

if(HasGBAFix)
	add_custom_command(
		TARGET rom.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary rom.elf rom.gba
		COMMAND ${GBAFixROM}
		COMMENT "Building ROM and fixing header"
		BYPRODUCTS rom.gba
	)

	add_custom_command(
		TARGET multiboot.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary multiboot.elf multiboot.gba
		COMMAND ${GBAFixMultiboot}
		COMMENT "Building Multiboot and fixing header"
		BYPRODUCTS multiboot.gba
	)
else()
	add_custom_command(
		TARGET rom.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary rom.elf rom.gba
		COMMENT "Building ROM (header not fixed)"
		BYPRODUCTS rom.gba
	)

	add_custom_command(
		TARGET multiboot.elf
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary multiboot.elf multiboot.gba
		COMMENT "Building Multiboot (header not fixed)"
		BYPRODUCTS multiboot.gba
	)
endif()
