cmake_minimum_required(VERSION 3.1)

project(rom C ASM)

add_library(rom STATIC crt0.s gba-irq.s gba-syscalls.c)

message(STATUS "Activating GBA ROM runtime")

#====================
# .specs
#====================

string(CONCAT ROM_SPECS
    "%rename link link_b\n"
    "\n"
    "*link:\n"
    "%(link_b) -T ${CMAKE_CURRENT_LIST_DIR}/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
    "\n"
    "*startfile:\n"
    "crti%O%s crtbegin%O%s ${CMAKE_CURRENT_BINARY_DIR}/librom.a%s\n"
    "\n"
)

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/runtime.specs" ${ROM_SPECS})