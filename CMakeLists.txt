cmake_minimum_required(VERSION 3.8)

project("GameBoyAdvance" ASM C CXX)
set(CMAKE_SYSTEM_NAME "GBA")

set(GameID "GAME")

set(PlatformTarget			"arm-none-eabi")
set(PlatformCore			"arm7tdmi")
set(PlatformArchitecture	"armv4t")
set(PlatformInstructionSet	"thumb")

if(${CONFIGURATION_NAME} STREQUAL ROM-Debug)
	set(ExecutableType ROM)
elseif (${CONFIGURATION_NAME} STREQUAL ROM-Release)
	set(ExecutableType ROM)
elseif (${CONFIGURATION_NAME} STREQUAL Multiboot-Debug)
	set(ExecutableType Multiboot)
elseif (${CONFIGURATION_NAME} STREQUAL Multiboot-Release)
	set(ExecutableType Multiboot)
endif()

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
	set(GBAFix ${devkitPro}/tools/bin/gbafix gbatemplate.gba -c${GameID})
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

string(TOLOWER ${ExecutableType} LinkFolder)

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
	set(CRT0BinaryPath "CMakeFiles/CRT0Code.dir/lib/${LinkFolder}/crt0.s.obj")
	set(SyscallsBinaryPath "CMakeFiles/CRT0Code.dir/lib/${LinkFolder}/gba-syscalls.c.obj")
else()
	set(CRT0BinaryPath "CMakeFiles/CRT0Code.dir/lib/${LinkFolder}/crt0.o")
	set(SyscallsBinaryPath "CMakeFiles/CRT0Code.dir/lib/${LinkFolder}/gba-syscalls.o")
endif()

set(SpecsPath "${CMAKE_BINARY_DIR}/gba.specs")
if(ExecutableType STREQUAL ROM)	
	file(GLOB CRT0Source "${PROJECT_SOURCE_DIR}/lib/${LinkFolder}/*.h" "${PROJECT_SOURCE_DIR}/lib/${LinkFolder}/*.s" "${PROJECT_SOURCE_DIR}/lib/${LinkFolder}/*.c")
	add_library(CRT0Code OBJECT ${CRT0Source})
	target_compile_options(CRT0Code PRIVATE "-mthumb")

	message(STATUS "Writing ROM specs")
	string(CONCAT SpecsContents
		"%rename link link_b\n"
		"\n"
		"*link:\n"
		"%(link_b) -T ${PROJECT_SOURCE_DIR}/lib/${LinkFolder}/gba.ld%s --gc-sections\n"
		"\n"
		"*startfile:\n"
		"${CMAKE_BINARY_DIR}/${CRT0BinaryPath}%s crti%O%s crtbegin%O%s ${CMAKE_BINARY_DIR}/${SyscallsBinaryPath}%s\n"
		"\n"
	)
	file(WRITE ${SpecsPath} ${SpecsContents})
endif()

#====================
# CMAKE
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
set(LinkerFlags "-specs=${SpecsPath} -lc_nano -lstdc++_nano")

set(CMAKE_ASM_LINK_FLAGS "${LinkerFlags}")
set(CMAKE_ASM_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_ASM_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_LINK_FLAGS "${LinkerFlags}")
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_CXX_LINK_FLAGS "${LinkerFlags}")
set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_CXX_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

#====================
# ELF
#====================

set(OutputELF gbatemplate.elf)
add_executable(${OutputELF})

if(MainSources)
	target_sources(${OutputELF} PUBLIC $<TARGET_OBJECTS:MainCode>)
endif()

if(thumbSources)
	target_sources(${OutputELF} PUBLIC $<TARGET_OBJECTS:thumbCode>)
endif()

if(ARMSources)
	target_sources(${OutputELF} PUBLIC $<TARGET_OBJECTS:ARMCode>)
endif()

if(IWRAMSources)
	target_sources(${OutputELF} PUBLIC $<TARGET_OBJECTS:IWRAMCode>)
endif()

if(EWRAMSources)
	target_sources(${OutputELF} PUBLIC $<TARGET_OBJECTS:EWRAMCode>)
endif()

#====================
# GBA
#====================

if(HasGBAFix)
	add_custom_command(
		TARGET ${OutputELF}
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary ${OutputELF} gbatemplate.gba
		COMMAND ${GBAFix}
		COMMENT "Building ROM and fixing header"
		BYPRODUCTS gbatemplate.gba
	)
else()
	add_custom_command(
		TARGET ${OutputELF}
		POST_BUILD
		COMMAND ${CMAKE_OBJCOPY} -O binary ${OutputELF} gbatemplate.gba
		COMMENT "Building ROM (header not fixed)"
		BYPRODUCTS gbatemplate.gba
	)
endif()
