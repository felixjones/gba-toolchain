set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(PlatformTarget			"arm-none-eabi")
set(PlatformCore			"arm7tdmi")
set(PlatformArchitecture	"armv4t")

#====================
# ARM GNU Toolchain
#====================

set(ARM_GNU_PATH ${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain)
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
	set(GBAFixROM "${devkitPro}/tools/bin/gbafix" rom.gba -c${GameID})
	set(GBAFixMultiboot "${devkitPro}/tools/bin/gbafix" multiboot.gba -c${GameID})
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
# CMake
#====================

set(CMAKE_ASM_COMPILER_WORKS 1)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

set(CMAKE_ASM_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

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

set(CMAKE_LINKER ${GCCBin}g++)

set(CMAKE_ASM_LINK_FLAGS "-lc")
set(CMAKE_ASM_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_ASM_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_LINK_FLAGS "-lc")
set(CMAKE_C_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_C_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_CXX_LINK_FLAGS "-lc -lstdc++")
set(CMAKE_CXX_LINK_EXECUTABLE "<CMAKE_LINKER> <CMAKE_CXX_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

#====================
# crt0 / syscalls
#====================

message(STATUS "Compiling crt0.o & gba-syscalls.o")
execute_process(
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.s
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.s
	COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -mthumb -O3 -I${ARM_GNU_PATH}/arm-none-eabi/include/ -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.c
	COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -mthumb -O3 -I${ARM_GNU_PATH}/arm-none-eabi/include/ -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.c
)

#====================
# Specs ROM
#====================

set(CRT0ROMOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.o")
set(SyscallsROMOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.o")

message(STATUS "Writing ROM specs")
string(CONCAT SpecsROMContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0ROMOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsROMOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba.specs" ${SpecsROMContents})

#====================
# Specs Multiboot
#====================

set(CRT0MultibootOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.o")
set(SyscallsMultibootOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.o")

message(STATUS "Writing Multiboot specs")
string(CONCAT SpecsMultibootContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0MultibootOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsMultibootOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba.specs" ${SpecsMultibootContents})

set(SpecsPath "${CMAKE_CURRENT_LIST_DIR}/lib/")
