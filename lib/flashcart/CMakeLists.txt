cmake_minimum_required(VERSION 3.0)

project(flashcart C ASM)

set(FatFsSources
    fatfs/source/ff.c
    fatfs/source/ffsystem.c
    fatfs/source/ffunicode.c
)

add_library(flashcart STATIC crt0.s gba-syscalls.c gba-dirent.c gba-time.c diskio.c disk_flash.c disk_everdrive.c disk_ezflash_iv.c disk_ezflash_omega.c everdrive.c ezflash.c ${FatFsSources})

if(GBA_TOOLCHAIN)
    gba_clang_minsizerel(CMAKE_C_FLAGS_MINSIZEREL)
    set(CMAKE_BUILD_TYPE MinSizeRel)
endif()

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

message(STATUS "Activating GBA flashcart runtime")

#====================
# .specs
#====================

string(CONCAT FLASHCART_SPECS
    "%rename link link_b\n"
    "\n"
    "*link:\n"
    "%(link_b) -T flashcart/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
    "\n"
    "*startfile:\n"
    "crti%O%s crtbegin%O%s flashcart/libflashcart.a%s\n"
    "\n"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/gba.ld" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/runtime.specs" ${FLASHCART_SPECS})

target_include_directories(flashcart SYSTEM PUBLIC "include/sys/")
