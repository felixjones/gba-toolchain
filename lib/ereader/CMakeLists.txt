cmake_minimum_required(VERSION 3.0)

project(ereader C ASM)

add_library(ereader STATIC crt0.s gba-syscalls.c)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mthumb -Wall -fno-strict-aliasing -Os")

message(STATUS "Activating GBA e-reader runtime")

#====================
# .specs
#====================

string(CONCAT EREADER_SPECS
    "%rename link link_b\n"
    "\n"
    "*link:\n"
    "%(link_b) -T ereader/gba.ld%s --gc-sections %:replace-outfile(-lc -lc_nano) %:replace-outfile(-lg -lg_nano) %:replace-outfile(-lrdimon -lrdimon_nano) %:replace-outfile(-lstdc++ -lstdc++_nano) %:replace-outfile(-lsupc++ -lsupc++_nano)\n"
    "\n"
    "*startfile:\n"
    "crti%O%s crtbegin%O%s ereader/libereader.a%s\n"
    "\n"
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/gba.ld" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/runtime.specs" ${EREADER_SPECS})
