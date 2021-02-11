cmake_minimum_required(VERSION 3.0)
project(tonclib)

add_executable(${CMAKE_PROJECT_NAME} main.c)
set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES SUFFIX ".elf")

#====================
# ROM information
#====================

set(ROM_TITLE "tonclib")
set(ROM_GAME_CODE "CTLE")
set(ROM_MAKER_CODE "GT")
set(ROM_VERSION 100)

#====================
# GBA toolchain
#====================

if(GBA_TOOLCHAIN)
    gba_target_link_tonc(${CMAKE_PROJECT_NAME})

    gba_target_sources_instruction_set(${CMAKE_PROJECT_NAME} thumb)
    gba_target_link_runtime(${CMAKE_PROJECT_NAME} rom)
    gba_target_object_copy(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.elf" "${CMAKE_PROJECT_NAME}.gba")

    if(EXISTS ${GBA_TOOLCHAIN_GBAFIX})
        gba_target_fix(${CMAKE_PROJECT_NAME} "${CMAKE_PROJECT_NAME}.gba" "${ROM_TITLE}" "${ROM_GAME_CODE}" "${ROM_MAKER_CODE}" ${ROM_VERSION})
    else()
        message(WARNING "gbafix is missing: install a host compiler (such as clang or gcc) and re-run CMake.\r\nROM WILL NOT WORK ON HARDWARE")
    endif()
endif()
