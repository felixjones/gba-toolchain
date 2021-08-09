cmake_minimum_required(VERSION 3.0)

project(flashcart C ASM)

set(FatFsSources
    fatfs/source/ff.c
    fatfs/source/ffsystem.c
    fatfs/source/ffunicode.c
)

add_library(flashcart STATIC crt0.s disk_flash.c disk_everdrive.s disk_ezflash.s diskio.c everdrive.c ezflash.c gba-syscalls.c ${FatFsSources})
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -mthumb -x assembler-with-cpp")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -fno-strict-aliasing -Og")

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
