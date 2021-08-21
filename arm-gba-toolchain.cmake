cmake_minimum_required(VERSION 3.0)

get_filename_component(TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}" NAME)
message(STATUS "Using toolchain: \"${TOOLCHAIN_FILE}\"")

include("${CMAKE_CURRENT_LIST_DIR}/cmake-include/DownloadDependencies.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake-include/FindCompilers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake-include/GBATarget.cmake")

set(GBA_TOOLCHAIN ON)

#====================
# Options
#====================

option(USE_CLANG "Enable Clang compiler" OFF)

#====================
# System
#====================

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

#====================
# Try compile
#====================

set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")

#====================
# Dependencies
#====================

gba_download_dependencies("https://raw.githubusercontent.com/felixjones/gba-toolchain/master/urls.txt")

#====================
# Compilers
#====================

list(APPEND CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include")
list(APPEND CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES "${CMAKE_SYSROOT}/include")

gba_find_compilers()

#====================
# Tools
#====================

set(GBA_TOOLCHAIN_TOOLS "${CMAKE_CURRENT_LIST_DIR}/tools/")

#====================
# GBAFix
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
    set(GBA_TOOLCHAIN_GBAFIX "${GBA_TOOLCHAIN_TOOLS}/gbafix/gbafix.exe")
else()
    set(GBA_TOOLCHAIN_GBAFIX "${GBA_TOOLCHAIN_TOOLS}/gbafix/gbafix")
endif()

#====================
# GBFS
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
    set(GBA_TOOLCHAIN_GBFS "${GBA_TOOLCHAIN_TOOLS}/gbfs/gbfs.exe")
    set(GBA_TOOLCHAIN_BIN2S "${GBA_TOOLCHAIN_TOOLS}/gbfs/bin2s.exe")
    set(GBA_TOOLCHAIN_PADBIN "${GBA_TOOLCHAIN_TOOLS}/gbfs/padbin.exe")
else()
    set(GBA_TOOLCHAIN_GBFS "${GBA_TOOLCHAIN_TOOLS}/gbfs/gbfs")
    set(GBA_TOOLCHAIN_BIN2S "${GBA_TOOLCHAIN_TOOLS}/gbfs/bin2s")
    set(GBA_TOOLCHAIN_PADBIN "${GBA_TOOLCHAIN_TOOLS}/gbfs/padbin")
endif()

#====================
# NEDENC
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
    set(GBA_TOOLCHAIN_NEDCMAKE "${GBA_TOOLCHAIN_TOOLS}/nedclib/nedcmake.exe")
else()
    set(GBA_TOOLCHAIN_NEDCMAKE "${GBA_TOOLCHAIN_TOOLS}/nedclib/nedcmake")
endif()

#====================
# Library projects
#====================

set(GBA_TOOLCHAIN_LIB_ROM_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/rom")
set(GBA_TOOLCHAIN_LIB_MULTIBOOT_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot")
set(GBA_TOOLCHAIN_LIB_EREADER_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/ereader")
set(GBA_TOOLCHAIN_LIB_FLASHCART_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/flashcart")
set(GBA_TOOLCHAIN_LIB_TONC_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
set(GBA_TOOLCHAIN_LIB_AGBABI_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/agbabi")
set(GBA_TOOLCHAIN_LIB_GBA_PLUSPLUS_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/gba-plusplus")
set(GBA_TOOLCHAIN_LIB_MAXMOD_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/maxmod")
set(GBA_TOOLCHAIN_LIB_GBFS_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/gbfs")
set(GBA_TOOLCHAIN_LIB_POSPRINTF_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/posprintf")
set(GBA_TOOLCHAIN_LIB_RTC_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/rtc")
