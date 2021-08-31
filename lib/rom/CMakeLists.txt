cmake_minimum_required(VERSION 3.0)

project(rom C ASM)

add_library(rom STATIC crt0.s gba-syscalls.c)

if(GBA_TOOLCHAIN)
    gba_clang_minsizerel(CMAKE_C_FLAGS_MINSIZEREL)
    set(CMAKE_BUILD_TYPE MinSizeRel)
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -Wextra -Wno-unused-parameter")

message(STATUS "Activating GBA ROM runtime")

#====================
# .specs
#====================

string(CONCAT ROM_SPECS
    "%rename link link_b\n"
    "\n"
    "*link:\n"
    "%(link_b) -T rom/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
    "\n"
    "*startfile:\n"
    "crti%O%s crtbegin%O%s rom/librom.a%s\n"
    "\n"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/gba.ld" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/runtime.specs" ${ROM_SPECS})
