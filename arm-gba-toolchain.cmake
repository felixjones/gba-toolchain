cmake_minimum_required(VERSION 3.6)

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
# GBAFix
#====================

if(CMAKE_HOST_SYSTEM_NAME STREQUAL Windows)
    set(GBA_TOOLCHAIN_GBAFIX "${CMAKE_CURRENT_LIST_DIR}/tools/gbafix.exe")
else()
    set(GBA_TOOLCHAIN_GBAFIX "${CMAKE_CURRENT_LIST_DIR}/tools/gbafix")
endif()

#====================
# Library projects
#====================

set(GBA_TOOLCHAIN_LIB_ROM_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/rom")
set(GBA_TOOLCHAIN_LIB_MULTIBOOT_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/multiboot")
set(GBA_TOOLCHAIN_LIB_TONC_DIR "${CMAKE_CURRENT_LIST_DIR}/lib/tonc")
