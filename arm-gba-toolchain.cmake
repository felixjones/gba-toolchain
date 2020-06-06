cmake_minimum_required(VERSION 3.1)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(PlatformTarget "arm-none-eabi")
set(PlatformCore "arm7tdmi")
set(PlatformArchitecture "armv4t")

#====================
# Compiler stuff
#====================

set(UseClang true)
set(UseModernCxx true)

#====================
# OS stuff
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
	set(BinarySuffix ".exe")
	set(DCMAKE_SH="CMAKE_SH-NOTFOUND")
else()
	set(BinarySuffix "")
endif()

#====================
# gbafix
#====================

set(GBAFIX_PATH "${CMAKE_CURRENT_LIST_DIR}/bin/gbafix")
if(NOT EXISTS "${GBAFIX_PATH}/")
	set(GBAFIX_SOURCE_FILE "${GBAFIX_PATH}/gbafix.c")
	set(GBAFIX_URL "https://raw.githubusercontent.com/devkitPro/gba-tools/master/src/gbafix.c")

	message(STATUS "Downloading gbafix.c from ${GBAFIX_URL} to ${GBAFIX_SOURCE_FILE}")
    file(DOWNLOAD "${GBAFIX_URL}" "${GBAFIX_SOURCE_FILE}")

	message(STATUS "Compiling gbafix")
	execute_process(COMMAND gcc -o "${GBAFIX_PATH}/gbafix${BinarySuffix}" "${GBAFIX_SOURCE_FILE}")
endif()

find_program(HasGBAFix "${GBAFIX_PATH}/gbafix")
if(HasGBAFix)
	message(STATUS "gbafix detected")
endif()

#====================
# GNU Arm Embedded Toolchain
#====================

set(ARM_GNU_PATH "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain")
if(NOT EXISTS "${ARM_GNU_PATH}/arm-none-eabi")
	set(ARM_GNU_URL_BASE "https://developer.arm.com/-/media/Files/downloads/gnu-rm")
	set(ARM_GNU_URL "${ARM_GNU_URL_BASE}/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update")

	if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
		set(ARM_GNU_URL "${ARM_GNU_URL}-win32.zip")
		set(ARM_GNU_ARCHIVE_PATH "${ARM_GNU_PATH}/gcc-arm-none-eabi.zip")
	elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Linux)
		set(ARM_GNU_URL "${ARM_GNU_URL}-x86_64-linux.tar.bz2")
		set(ARM_GNU_ARCHIVE_PATH "${ARM_GNU_PATH}/gcc-arm-none-eabi.tar.bz2")
	elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL Darwin)
		set(ARM_GNU_URL "${ARM_GNU_URL}-mac.tar.bz2")
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
			COMMAND tar -xvf "${ARM_GNU_ARCHIVE_PATH}" -C "${ARM_GNU_PATH}/" --strip-components=1
		)
	endif()
endif()

set(GDBPath "${CMAKE_CURRENT_LIST_DIR}/arm-gnu-toolchain/bin")
set(GDBExecutable "arm-none-eabi-gdb${BinarySuffix}")
set(IncludePaths "-I${ARM_GNU_PATH}/arm-none-eabi/include/ -I${ARM_GNU_PATH}/arm-none-eabi/include/c++/9.3.1/ -I${ARM_GNU_PATH}/arm-none-eabi/include/c++/9.3.1/arm-none-eabi/ -I${ARM_GNU_PATH}/lib/gcc/arm-none-eabi/9.3.1/include")

#====================
# gbaplusplus
#====================

set(GBAPLUSPLUS_PATH "${CMAKE_CURRENT_LIST_DIR}/lib")
if(NOT EXISTS "${GBAPLUSPLUS_PATH}/gbaplusplus")
	set(GBAPLUSPLUS_ARCHIVE_PATH "${GBAPLUSPLUS_PATH}/gbaplusplus.zip")
	set(GBAPLUSPLUS_URL "https://github.com/felixjones/gbaplusplus/archive/master.zip")

	message(STATUS "Downloading gbaplusplus from ${GBAPLUSPLUS_URL} to ${GBAPLUSPLUS_ARCHIVE_PATH}")
    file(DOWNLOAD "${GBAPLUSPLUS_URL}" "${GBAPLUSPLUS_ARCHIVE_PATH}")

	message(STATUS "Extracting gbaplusplus to ${GBAPLUSPLUS_PATH}")
	if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
		execute_process(
			COMMAND powershell.exe -nologo -noprofile -command "& { Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('${GBAPLUSPLUS_ARCHIVE_PATH}', '${GBAPLUSPLUS_PATH}/'); }"
		)
	else()
		execute_process(
			COMMAND tar -xvf "${GBAPLUSPLUS_ARCHIVE_PATH}" -C "${GBAPLUSPLUS_PATH}/"
		)
	endif()
	file(RENAME "${GBAPLUSPLUS_PATH}/gbaplusplus-master/" "${GBAPLUSPLUS_PATH}/gbaplusplus/")
endif()

#====================
# GCC
#====================

set(GCCBin "${ARM_GNU_PATH}/bin/${PlatformTarget}-")

find_program(HasGCC "${GCCBin}gcc" "${GCCBin}g++")
if(HasGCC)
	set(CompilerASM "${GCCBin}as${BinarySuffix}")
	set(CompilerC "${GCCBin}gcc${BinarySuffix}")
	set(CompilerCXX "${GCCBin}g++${BinarySuffix}")
	set(CompilerFlags "-Wno-packed-bitfield-compat ${IncludePaths}")
else()
	message(FATAL_ERROR "Failed to locate ARM GNU GCC")
endif()

set(GCCAs "${GCCBin}as${BinarySuffix}")
set(GCCAr "${GCCBin}gcc-ar${BinarySuffix}")
set(GCCObjcopy "${GCCBin}objcopy${BinarySuffix}")
set(GCCStrip "${GCCBin}strip${BinarySuffix}")
set(GCCNm "${GCCBin}gcc-nm${BinarySuffix}")
set(GCCRanlib "${GCCBin}gcc-ranlib${BinarySuffix}")

#====================
# Clang
#====================

if(${UseClang})
	find_program(HasClang "clang" "clang++")
	if(HasClang)
		set(CompilerC "clang${BinarySuffix}")
		set(CompilerCXX "clang++${BinarySuffix}")
		set(CompilerFlags "--target=arm-arm-none-eabi -mfpu=none -isystem${ARM_GNU_PATH}/arm-none-eabi/include/ ${IncludePaths}")
		message(STATUS "Clang activated")
	endif()
endif()

#====================
# Language
#====================

set(ASMFlags "-mcpu=${PlatformCore} -mtune=${PlatformCore} -march=${PlatformArchitecture} -mfloat-abi=soft -Wall -Wpedantic -fomit-frame-pointer -ffast-math")
set(SharedFlags "${CompilerFlags} ${ASMFlags} -I${GBAPLUSPLUS_PATH}/gbaplusplus/include/")
set(CFlags "${SharedFlags}")
set(CXXFlags "${SharedFlags} -fno-rtti -fno-exceptions")

#====================
# CMake
#====================

if(${UseModernCxx})
	if(${CMAKE_VERSION} VERSION_LESS_EQUAL "3.8")
		set(CMAKE_CXX_STANDARD 14)
	elseif(${CMAKE_VERSION} VERSION_LESS "3.12")
		set(CMAKE_CXX_STANDARD 17)
	else()
		set(CMAKE_CXX_STANDARD 20)
	endif()
else()
	set(CMAKE_CXX_STANDARD 14)
endif()

set(CMAKE_CXX_EXTENSIONS OFF)

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

set(CMAKE_ASM_LINK_FLAGS "-lc")
set(CMAKE_ASM_LINK_EXECUTABLE "${GCCBin}g++${BinarySuffix} <CMAKE_ASM_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_C_LINK_FLAGS "-lc")
set(CMAKE_C_LINK_EXECUTABLE "${GCCBin}g++${BinarySuffix} <CMAKE_C_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

set(CMAKE_CXX_LINK_FLAGS "-lc -lstdc++")
set(CMAKE_CXX_LINK_EXECUTABLE "${GCCBin}g++${BinarySuffix} <CMAKE_CXX_LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")

#====================
# crt0 / syscalls
#====================

message(STATUS "Compiling crt0.o, gba-irq.o and gba-syscalls.o")
execute_process(
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.s
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.s
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-irq.o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-irq.s
	COMMAND ${CMAKE_ASM_COMPILER} -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-irq.o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-irq.s
	COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -mthumb -O3 -I${ARM_GNU_PATH}/arm-none-eabi/include/ -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.o ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.c
	COMMAND ${CMAKE_C_COMPILER} ${CMAKE_C_FLAGS} -mthumb -O3 -I${ARM_GNU_PATH}/arm-none-eabi/include/ -c -o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.o ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.c
)

#====================
# Specs ROM
#====================

set(CRT0ROMOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/rom/crt0.o")
set(IrqROMOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-irq.o")
set(SyscallsROMOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba-syscalls.o")

message(STATUS "Writing ROM specs")
string(CONCAT SpecsROMContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0ROMOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsROMOutputPath}%s ${IrqROMOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_CURRENT_LIST_DIR}/lib/rom/gba.specs" ${SpecsROMContents})

#====================
# Specs Multiboot
#====================

set(CRT0MultibootOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/crt0.o")
set(IrqMultibootOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-irq.o")
set(SyscallsMultibootOutputPath "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba-syscalls.o")

message(STATUS "Writing Multiboot specs")
string(CONCAT SpecsMultibootContents
	"%rename link link_b\n"
	"\n"
	"*link:\n"
	"%(link_b) -T ${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
	"\n"
	"*startfile:\n"
	"${CRT0MultibootOutputPath}%s crti%O%s crtbegin%O%s ${SyscallsMultibootOutputPath}%s ${IrqMultibootOutputPath}%s\n"
	"\n"
)
file(WRITE "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot/gba.specs" ${SpecsMultibootContents})

set(SpecsPath "${CMAKE_CURRENT_LIST_DIR}/lib/")
