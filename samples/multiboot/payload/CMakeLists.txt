cmake_minimum_required(VERSION 3.0)
project(multiboot C)

add_executable(payload main.c)
set_target_properties(payload PROPERTIES SUFFIX ".elf")

#====================
# ROM information
#====================

set(ROM_TITLE "payload")
set(ROM_GAME_CODE "CPLE")
set(ROM_MAKER_CODE "GT")
set(ROM_VERSION 100)

#====================
# GBA toolchain
#====================

if(GBA_TOOLCHAIN)
    gba_target_link_tonc(payload)

    gba_target_sources_instruction_set(payload thumb)
    gba_target_link_runtime(payload multiboot)
    gba_target_object_copy(payload "payload.elf" "payload.mb")

    gba_target_fix(payload "payload.mb" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
endif()
